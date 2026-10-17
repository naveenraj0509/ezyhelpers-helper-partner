from datetime import timedelta

from django.contrib.auth.models import User
from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.authtoken.models import Token
from rest_framework.test import APITestCase

from .models import Job


def make_job(helper, job_status=Job.Status.ASSIGNED, title="Deep cleaning"):
    return Job.objects.create(
        helper=helper,
        title=title,
        customer_name="Meera Nair",
        address="Flat 402, Koramangala, Bengaluru",
        scheduled_for=timezone.now() + timedelta(hours=2),
        status=job_status,
    )


class JobApiTestCase(APITestCase):
    """Shared fixture: two helpers, each with their own job."""

    def setUp(self):
        self.asha = User.objects.create_user("asha", password="helper1234")
        self.ravi = User.objects.create_user("ravi", password="helper1234")
        self.asha_job = make_job(self.asha, title="Asha job")
        self.ravi_job = make_job(self.ravi, title="Ravi job")

    def authenticate_as(self, user):
        token, _ = Token.objects.get_or_create(user=user)
        self.client.credentials(HTTP_AUTHORIZATION=f"Token {token.key}")

    def status_url(self, job):
        return reverse("job-update-status", args=[job.id])


class LoginTests(JobApiTestCase):
    def test_valid_credentials_return_a_token(self):
        response = self.client.post(
            reverse("login"), {"username": "asha", "password": "helper1234"}
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.data["token"])
        self.assertEqual(response.data["user"]["username"], "asha")

    def test_wrong_password_is_rejected(self):
        response = self.client.post(
            reverse("login"), {"username": "asha", "password": "wrong-password"}
        )

        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
        self.assertNotIn("token", response.data)

    def test_job_list_requires_authentication(self):
        response = self.client.get(reverse("job-list"))

        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


class OwnershipTests(JobApiTestCase):
    def test_list_contains_only_the_signed_in_helpers_jobs(self):
        self.authenticate_as(self.asha)

        response = self.client.get(reverse("job-list"))

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        titles = [job["title"] for job in response.data["results"]]
        self.assertEqual(titles, ["Asha job"])

    def test_cannot_read_another_helpers_job(self):
        self.authenticate_as(self.asha)

        response = self.client.get(reverse("job-detail", args=[self.ravi_job.id]))

        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_cannot_update_another_helpers_job(self):
        self.authenticate_as(self.asha)

        response = self.client.patch(
            self.status_url(self.ravi_job), {"status": Job.Status.IN_PROGRESS}
        )

        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
        self.ravi_job.refresh_from_db()
        self.assertEqual(self.ravi_job.status, Job.Status.ASSIGNED)


class StatusTransitionTests(JobApiTestCase):
    def test_assigned_moves_to_in_progress(self):
        self.authenticate_as(self.asha)

        response = self.client.patch(
            self.status_url(self.asha_job), {"status": Job.Status.IN_PROGRESS}
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.asha_job.refresh_from_db()
        self.assertEqual(self.asha_job.status, Job.Status.IN_PROGRESS)
        self.assertEqual(response.data["next_statuses"], [Job.Status.COMPLETED])

    def test_cannot_skip_straight_to_completed(self):
        self.authenticate_as(self.asha)

        response = self.client.patch(
            self.status_url(self.asha_job), {"status": Job.Status.COMPLETED}
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.asha_job.refresh_from_db()
        self.assertEqual(self.asha_job.status, Job.Status.ASSIGNED)

    def test_cannot_reopen_a_completed_job(self):
        completed_job = make_job(self.asha, Job.Status.COMPLETED, title="Finished job")
        self.authenticate_as(self.asha)

        response = self.client.patch(
            self.status_url(completed_job), {"status": Job.Status.IN_PROGRESS}
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        completed_job.refresh_from_db()
        self.assertEqual(completed_job.status, Job.Status.COMPLETED)

    def test_unknown_status_value_is_rejected(self):
        self.authenticate_as(self.asha)

        response = self.client.patch(self.status_url(self.asha_job), {"status": "CANCELLED"})

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.asha_job.refresh_from_db()
        self.assertEqual(self.asha_job.status, Job.Status.ASSIGNED)
