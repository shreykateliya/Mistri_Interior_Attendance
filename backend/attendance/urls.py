from django.urls import path
from .views import PunchInView, login_view, admin_dashboard_data, force_logout

urlpatterns = [
    path('punch-in/', PunchInView.as_view(), name='punch-in'),
    path('login/', login_view, name='login'),
    path('admin/dashboard/', admin_dashboard_data, name='admin-dashboard'),
    path('admin/force-logout/', force_logout, name='force-logout'),
]