from django.urls import path
from .views import (
    PunchInView, login_view, signup_view, change_password, 
    UpdateProfilePic, admin_dashboard_data, force_logout,
    forgot_password, reset_password_confirm,
    monthly_report, delete_log  # <--- ADD THESE TWO HERE
)

urlpatterns = [
    # Employee Actions
    path('punch-in/', PunchInView.as_view()),
    path('login/', login_view),
    path('signup/', signup_view),
    path('change-password/', change_password),
    path('forgot-password/', forgot_password),
    path('reset-password-confirm/', reset_password_confirm),
    path('update-profile-pic/', UpdateProfilePic.as_view()),

    # Admin Actions
    path('admin/dashboard/', admin_dashboard_data),
    path('admin/force-logout/', force_logout),

    # Reports & Management (NEW)
    path('report/monthly/', monthly_report),      # <--- New Report API
    path('log/delete/<int:log_id>/', delete_log), # <--- New Delete API
]