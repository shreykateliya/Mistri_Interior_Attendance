from rest_framework.views import APIView
from rest_framework.decorators import api_view, parser_classes
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework import status
from django.contrib.auth import authenticate
from .models import AttendanceLog, Employee
from .serializers import AttendanceLogSerializer

# 1. SMART LOGIN (Returns Profile Pic & Current Status)
@api_view(['POST'])
def login_view(request):
    username = request.data.get('username')
    password = request.data.get('password')
    
    # A. ADMIN LOGIN
    user = authenticate(username=username, password=password)
    if user is not None:
        return Response({"status": "success", "role": "admin", "username": user.username})
    
    # B. EMPLOYEE LOGIN
    try:
        emp = Employee.objects.get(name__iexact=username)
        
        # Check their last action to decide button state (In vs Out)
        last_log = AttendanceLog.objects.filter(employee=emp).order_by('-timestamp').first()
        current_status = "OUT" # Default
        if last_log and last_log.type == 'IN':
            current_status = "IN"

        return Response({
            "status": "success", 
            "role": "employee", 
            "username": emp.name,
            "profile_pic": emp.profile_pic.url if emp.profile_pic else "",
            "current_status": current_status 
        })
    except Employee.DoesNotExist:
        return Response({"status": "error", "message": "User not found"}, status=400)

# 2. PUNCH IN / OUT (Handles Logic)
# In backend/attendance/views.py

# ... keep your imports ...

class PunchInView(APIView):
    parser_classes = (MultiPartParser, FormParser)

    def post(self, request, *args, **kwargs):
        print("Received Data:", request.data) # Debugging
        
        # 1. Get the Name sent from App
        employee_name = request.data.get('employee_id')
        
        if not employee_name:
             return Response({"error": "Employee name missing"}, status=400)

        # 2. Find the Employee Object
        try:
            emp = Employee.objects.get(name__iexact=employee_name)
        except Employee.DoesNotExist:
            return Response({"error": f"Employee '{employee_name}' not found"}, status=400)

        # 3. Validate Data (Excluding employee, since it's read_only now)
        serializer = AttendanceLogSerializer(data=request.data)
        
        if serializer.is_valid():
            # 4. CRITICAL FIX: Pass the employee object explicitly here
            serializer.save(employee=emp)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        else:
            print("Serializer Errors:", serializer.errors) # Shows exact error in terminal
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
# 3. ADMIN: GET ALL EMPLOYEE STATUS (Who is working right now?)
@api_view(['GET'])
def admin_dashboard_data(request):
    employees = Employee.objects.all()
    data = []
    
    for emp in employees:
        # Get last log to see if they are IN or OUT
        last_log = AttendanceLog.objects.filter(employee=emp).order_by('-timestamp').first()
        is_working = False
        last_seen = "Never"
        
        if last_log:
            is_working = (last_log.type == 'IN')
            last_seen = last_log.timestamp.strftime("%I:%M %p") # e.g. 09:30 AM

        data.append({
            "id": emp.id,
            "name": emp.name,
            "profile_pic": emp.profile_pic.url if emp.profile_pic else "",
            "is_working": is_working,
            "last_seen": last_seen
        })
    return Response(data)

# 4. ADMIN: FORCE LOGOUT
@api_view(['POST'])
def force_logout(request):
    emp_id = request.data.get('employee_id')
    try:
        emp = Employee.objects.get(id=emp_id)
        # Create a "Punch Out" log automatically
        AttendanceLog.objects.create(employee=emp, type='OUT', forced_by_admin=True)
        return Response({"status": "success", "message": f"Forced logout for {emp.name}"})
    except Employee.DoesNotExist:
        return Response({"error": "Employee not found"}, status=400)