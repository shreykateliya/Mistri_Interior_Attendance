from rest_framework.views import APIView
from rest_framework.decorators import api_view, parser_classes
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework import status
from django.contrib.auth import authenticate, update_session_auth_hash
from django.contrib.auth.models import User
from .models import AttendanceLog, Employee
from .serializers import AttendanceLogSerializer
import random
from django.core.mail import send_mail



# 1. GENERATE OTP & SEND EMAIL
@api_view(['POST'])
def forgot_password(request):
    username = request.data.get('username')
    
    try:
        emp = Employee.objects.get(name__iexact=username)
        
        # Generate 4-digit OTP
        otp_code = str(random.randint(1000, 9999))
        emp.otp = otp_code
        emp.save()
        
        # Send Email (Or print to console)
        subject = "Mistri App: Password Reset Code"
        message = f"Hello {emp.name},\n\nYour OTP to reset password is: {otp_code}\n\nDo not share this."
        
        if emp.email:
            send_mail(subject, message, 'admin@mistri.com', [emp.email], fail_silently=False)
            return Response({"status": "success", "message": f"OTP sent to {emp.email}"})
        else:
            # Fallback if no email is saved
            print(f"------------\nOTP for {emp.name}: {otp_code}\n------------")
            return Response({"status": "success", "message": "OTP generated (Check Admin Console)"})
            
    except Employee.DoesNotExist:
        return Response({"status": "error", "message": "User not found"}, status=400)

# 2. VERIFY OTP & RESET PASSWORD
@api_view(['POST'])
def reset_password_confirm(request):
    username = request.data.get('username')
    otp = request.data.get('otp')
    new_password = request.data.get('new_password')
    
    try:
        emp = Employee.objects.get(name__iexact=username)
        
        if emp.otp == otp:
            emp.password = new_password
            emp.otp = None # Clear OTP after use
            emp.save()
            return Response({"status": "success", "message": "Password Reset Successfully!"})
        else:
            return Response({"status": "error", "message": "Invalid OTP"}, status=400)
            
    except Employee.DoesNotExist:
        return Response({"status": "error", "message": "User not found"}, status=400)

# 1. SIGN UP (For New Employees)
@api_view(['POST'])
def signup_view(request):
    username = request.data.get('username')
    password = request.data.get('password')
    
    if Employee.objects.filter(name__iexact=username).exists():
        return Response({"status": "error", "message": "Employee name already exists!"}, status=400)
    
    # Create new employee
    emp = Employee.objects.create(name=username, password=password)
    return Response({"status": "success", "message": "Account created! Please Login."})

# 2. SECURE LOGIN (Checks Password for Everyone)
@api_view(['POST'])
def login_view(request):
    username = request.data.get('username')
    password = request.data.get('password')
    
    # A. ADMIN LOGIN (Django Superuser)
    user = authenticate(username=username, password=password)
    if user is not None:
        return Response({"status": "success", "role": "admin", "username": user.username, "id": user.id})
    
    # B. EMPLOYEE LOGIN (Check custom password)
    try:
        emp = Employee.objects.get(name__iexact=username)
        if emp.password == password:
            # Get Status
            last_log = AttendanceLog.objects.filter(employee=emp).order_by('-timestamp').first()
            current_status = "OUT"
            if last_log and last_log.type == 'IN':
                current_status = "IN"

            return Response({
                "status": "success", 
                "role": "employee", 
                "id": emp.id,
                "username": emp.name,
                "profile_pic": emp.profile_pic.url if emp.profile_pic else "",
                "current_status": current_status 
            })
        else:
            return Response({"status": "error", "message": "Wrong Password"}, status=400)
            
    except Employee.DoesNotExist:
        return Response({"status": "error", "message": "User not found"}, status=400)

# 3. CHANGE PASSWORD (For Logged In Users)
@api_view(['POST'])
def change_password(request):
    role = request.data.get('role')
    user_id = request.data.get('id')
    new_pass = request.data.get('new_password')
    
    if role == 'admin':
        u = User.objects.get(id=user_id)
        u.set_password(new_pass)
        u.save()
        return Response({"status": "success", "message": "Admin Password Changed"})
    
    else:
        emp = Employee.objects.get(id=user_id)
        emp.password = new_pass
        emp.save()
        return Response({"status": "success", "message": "Employee Password Changed"})

# 4. UPDATE PROFILE PIC
class UpdateProfilePic(APIView):
    parser_classes = (MultiPartParser, FormParser)

    def post(self, request, *args, **kwargs):
        emp_id = request.data.get('id')
        photo = request.FILES.get('profile_pic')
        
        try:
            emp = Employee.objects.get(id=emp_id)
            emp.profile_pic = photo
            emp.save()
            return Response({"status": "success", "new_url": emp.profile_pic.url})
        except Employee.DoesNotExist:
            return Response({"error": "User not found"}, status=400)

# 5. PUNCH IN LOGIC (Unchanged)
# backend/attendance/views.py (Partial Update - Just replace PunchInView)

# ... keep your imports ...

class PunchInView(APIView):
    parser_classes = (MultiPartParser, FormParser)

    def post(self, request, *args, **kwargs):
        # 1. Get the Name
        employee_name = request.data.get('employee_id')
        if not employee_name:
            return Response({"error": "Employee name is missing"}, status=400)

        # 2. Find the Employee Object
        try:
            emp = Employee.objects.get(name__iexact=employee_name)
        except Employee.DoesNotExist:
            return Response({"error": f"Employee '{employee_name}' not found"}, status=400)

        # 3. Validate OTHER data (Photo, Latitude, Longitude)
        # We pass request.data directly. The serializer will ignore 'employee' because it's read-only now.
        serializer = AttendanceLogSerializer(data=request.data)
        
        if serializer.is_valid():
            # 4. CRITICAL FIX: Manually attach the employee object here
            serializer.save(employee=emp)
            return Response({"status": "success", "type": request.data.get('type')}, status=201)
        else:
            print("Serializer Error:", serializer.errors)
            return Response(serializer.errors, status=400)

# 6. ADMIN DASHBOARD (Unchanged)
@api_view(['GET'])
def admin_dashboard_data(request):
    employees = Employee.objects.all()
    data = []
    for emp in employees:
        last_log = AttendanceLog.objects.filter(employee=emp).order_by('-timestamp').first()
        is_working = (last_log and last_log.type == 'IN')
        last_seen = last_log.timestamp.strftime("%I:%M %p") if last_log else "Never"
        data.append({
            "id": emp.id,
            "name": emp.name,
            "profile_pic": emp.profile_pic.url if emp.profile_pic else "",
            "is_working": is_working,
            "last_seen": last_seen
        })
    return Response(data)

@api_view(['POST'])
def force_logout(request):
    emp_id = request.data.get('employee_id')
    AttendanceLog.objects.create(employee_id=emp_id, type='OUT', forced_by_admin=True)
    return Response({"status": "success"})