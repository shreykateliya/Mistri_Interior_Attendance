from django.contrib import admin
from .models import Employee, AttendanceLog

admin.site.register(Employee)
admin.site.register(AttendanceLog)