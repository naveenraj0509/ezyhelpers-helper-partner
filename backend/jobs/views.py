from django.contrib.auth import authenticate
from rest_framework import status as http_status
from rest_framework import viewsets
from rest_framework.authtoken.models import Token
from rest_framework.decorators import action
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Job
from .serializers import JobSerializer, JobStatusUpdateSerializer, LoginSerializer


class LoginView(APIView):
    """POST /api/auth/login/ -> auth token for a helper."""

    authentication_classes = []
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        user = authenticate(
            request,
            username=serializer.validated_data["username"],
            password=serializer.validated_data["password"],
        )
        if user is None:
            return Response(
                {"detail": "Invalid username or password."},
                status=http_status.HTTP_401_UNAUTHORIZED,
            )

        token, _ = Token.objects.get_or_create(user=user)
        return Response(
            {
                "token": token.key,
                "user": {
                    "id": user.id,
                    "username": user.username,
                    "full_name": user.get_full_name() or user.username,
                },
            }
        )


class JobViewSet(viewsets.ReadOnlyModelViewSet):
    """Read-only job access, plus a guarded status transition endpoint."""

    serializer_class = JobSerializer

    def get_queryset(self):
        # Ownership is enforced here, so an unowned id is a 404 everywhere below.
        queryset = Job.objects.filter(helper=self.request.user)
        requested_status = self.request.query_params.get("status")
        if requested_status:
            queryset = queryset.filter(status=requested_status.upper())
        return queryset

    @action(detail=True, methods=["patch"], url_path="status")
    def update_status(self, request, pk=None):
        job = self.get_object()
        serializer = JobStatusUpdateSerializer(data=request.data, context={"job": job})
        serializer.is_valid(raise_exception=True)

        job.status = serializer.validated_data["status"]
        job.save(update_fields=["status", "updated_at"])
        return Response(JobSerializer(job).data)
