from django.conf import settings
from django.db import models


class Job(models.Model):
    """A single visit assigned to exactly one helper."""

    class Status(models.TextChoices):
        ASSIGNED = "ASSIGNED", "Assigned"
        IN_PROGRESS = "IN_PROGRESS", "In progress"
        COMPLETED = "COMPLETED", "Completed"

    # A helper may only move a job forward, one step at a time.
    ALLOWED_TRANSITIONS = {
        Status.ASSIGNED: {Status.IN_PROGRESS},
        Status.IN_PROGRESS: {Status.COMPLETED},
        Status.COMPLETED: set(),
    }

    helper = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="jobs",
    )
    title = models.CharField(max_length=120)
    description = models.TextField(blank=True)
    customer_name = models.CharField(max_length=120)
    customer_phone = models.CharField(max_length=20, blank=True)
    address = models.TextField()
    scheduled_for = models.DateTimeField()
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.ASSIGNED,
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["scheduled_for", "id"]

    def __str__(self):
        return f"{self.title} ({self.status})"

    def allowed_next_statuses(self):
        return sorted(self.ALLOWED_TRANSITIONS.get(self.status, set()))

    def can_move_to(self, new_status):
        return new_status in self.ALLOWED_TRANSITIONS.get(self.status, set())
