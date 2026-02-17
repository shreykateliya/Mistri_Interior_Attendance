from django.db import models

class Employee(models.Model):
    name = models.CharField(max_length=100)
    employee_id = models.CharField(max_length=20, unique=True, null=True, blank=True)
    password = models.CharField(max_length=100, default="1234")
    profile_pic = models.ImageField(upload_to='profiles/', null=True, blank=True)
    
    # NEW FIELDS FOR RESET
    email = models.EmailField(max_length=254, null=True, blank=True) # To send OTP
    otp = models.CharField(max_length=6, null=True, blank=True)      # Stores 123456
    
    def __str__(self):
        return self.name

# ... (Keep AttendanceLog class exactly as it was) ...

class AttendanceLog(models.Model):
    employee = models.ForeignKey(Employee, on_delete=models.CASCADE)
    live_photo = models.ImageField(upload_to='attendance_photos/', null=True, blank=True)
    latitude = models.DecimalField(max_digits=20, decimal_places=15, null=True, blank=True)
    longitude = models.DecimalField(max_digits=20, decimal_places=15, null=True, blank=True)
    timestamp = models.DateTimeField(auto_now_add=True)
    
    PUNCH_CHOICES = [('IN', 'Punch In'), ('OUT', 'Punch Out')]
    type = models.CharField(max_length=3, choices=PUNCH_CHOICES, default='IN')
    forced_by_admin = models.BooleanField(default=False)

    def __str__(self):
        return f"{self.employee.name} - {self.type}"