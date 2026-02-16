from rest_framework import serializers
from .models import AttendanceLog

class AttendanceLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = AttendanceLog
        fields = ['id', 'employee', 'live_photo', 'latitude', 'longitude', 'timestamp', 'type', 'forced_by_admin']
        # CRITICAL FIX: Make employee read-only so we can set it manually in views.py
        read_only_fields = ['employee', 'timestamp', 'forced_by_admin']
        
        # CRITICAL FIX: Make photo optional so validation doesn't fail if camera bugs out
        extra_kwargs = {
            'live_photo': {'required': False}
        }