from rest_framework import serializers

from .models import Job


class LoginSerializer(serializers.Serializer):
    username = serializers.CharField()
    password = serializers.CharField(write_only=True, style={"input_type": "password"})


class JobSerializer(serializers.ModelSerializer):
    # Lets the app render the right action button without duplicating the rules.
    next_statuses = serializers.SerializerMethodField()

    class Meta:
        model = Job
        fields = [
            "id",
            "title",
            "description",
            "customer_name",
            "customer_phone",
            "address",
            "scheduled_for",
            "status",
            "next_statuses",
            "created_at",
            "updated_at",
        ]
        read_only_fields = fields

    def get_next_statuses(self, job):
        return job.allowed_next_statuses()


class JobStatusUpdateSerializer(serializers.Serializer):
    status = serializers.ChoiceField(choices=Job.Status.choices)

    def validate_status(self, new_status):
        job = self.context["job"]
        if new_status == job.status:
            raise serializers.ValidationError(f"Job is already {new_status}.")
        if not job.can_move_to(new_status):
            allowed = job.allowed_next_statuses()
            allowed_text = ", ".join(allowed) if allowed else "no further changes"
            raise serializers.ValidationError(
                f"Cannot move a {job.status} job to {new_status}. Allowed: {allowed_text}."
            )
        return new_status
