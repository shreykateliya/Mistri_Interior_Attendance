from django.urls import path
from .views import (
    PunchInView, login_view, signup_view, change_password, 
    UpdateProfilePic, admin_dashboard_data, force_logout,
    forgot_password, reset_password_confirm # <--- Import new views
)

urlpatterns = [
    path('punch-in/', PunchInView.as_view()),
    path('login/', login_view),
    path('signup/', signup_view),
    path('change-password/', change_password),
    path('update-profile-pic/', UpdateProfilePic.as_view()),
    path('admin/dashboard/', admin_dashboard_data),
    path('admin/force-logout/', force_logout),
    path('forgot-password/', forgot_password),
    path('reset-password-confirm/', reset_password_confirm),
]