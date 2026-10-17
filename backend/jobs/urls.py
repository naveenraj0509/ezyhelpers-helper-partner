from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import JobViewSet, LoginView

router = DefaultRouter()
router.register(r"jobs", JobViewSet, basename="job")

urlpatterns = [
    path("auth/login/", LoginView.as_view(), name="login"),
    path("", include(router.urls)),
]
