from django.db import models

class Employee(models.Model):
    name = models.CharField(max_length=100)
    employee_id = models.CharField(max_length=20, unique=True, null=True, blank=True)
    # New: Profile Picture for the "Insta-like" feel
    profile_pic = models.ImageField(upload_to='profiles/', null=True, blank=True)
    
    def __str__(self):
        return self.name

class AttendanceLog(models.Model):
    employee = models.ForeignKey(Employee, on_delete=models.CASCADE)
    live_photo = models.ImageField(upload_to='attendance_photos/', null=True, blank=True)
    
    # CHANGED: Increased max_digits to 12 and decimal_places to 10
    latitude = models.DecimalField(max_digits=12, decimal_places=10, null=True, blank=True)
    longitude = models.DecimalField(max_digits=12, decimal_places=10, null=True, blank=True)
    
    timestamp = models.DateTimeField(auto_now_add=True)
    
    PUNCH_CHOICES = [('IN', 'Punch In'), ('OUT', 'Punch Out')]
    type = models.CharField(max_length=3, choices=PUNCH_CHOICES, default='IN')
    
    forced_by_admin = models.BooleanField(default=False)

    def __str__(self):
        return f"{self.employee.name} - {self.type} - {self.timestamp}"