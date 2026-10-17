from datetime import timedelta

from django.contrib.auth.models import User
from django.core.management.base import BaseCommand
from django.utils import timezone

from jobs.models import Job

DEMO_PASSWORD = "helper1234"

# Two helpers, so reviewers can see that ownership filtering actually works.
HELPERS = [
    {
        "username": "asha",
        "first_name": "Asha",
        "last_name": "Kumari",
        "jobs": [
            {
                "title": "Deep cleaning - 2BHK",
                "description": "Kitchen, two bathrooms and balcony. Customer has a pet cat.",
                "customer_name": "Meera Nair",
                "customer_phone": "+91 90000 11111",
                "address": "Flat 402, Brigade Residency, Koramangala, Bengaluru 560034",
                "offset_hours": 2,
                "status": Job.Status.ASSIGNED,
            },
            {
                "title": "Cooking - lunch for 4",
                "description": "South Indian vegetarian. Groceries already at home.",
                "customer_name": "Rohit Sharma",
                "customer_phone": "+91 90000 22222",
                "address": "12, 3rd Cross, Indiranagar, Bengaluru 560038",
                "offset_hours": 5,
                "status": Job.Status.ASSIGNED,
            },
            {
                "title": "Babysitting - evening shift",
                "description": "One child, age 4. Parents back by 9 PM.",
                "customer_name": "Divya Rao",
                "customer_phone": "+91 90000 33333",
                "address": "Sobha Dream Acres, Panathur, Bengaluru 560087",
                "offset_hours": 8,
                "status": Job.Status.IN_PROGRESS,
            },
            {
                "title": "Utensil washing - morning",
                "description": "Completed yesterday, kept for history.",
                "customer_name": "Imran Qureshi",
                "customer_phone": "+91 90000 44444",
                "address": "Prestige Shantiniketan, Whitefield, Bengaluru 560066",
                "offset_hours": -20,
                "status": Job.Status.COMPLETED,
            },
        ],
    },
    {
        "username": "ravi",
        "first_name": "Ravi",
        "last_name": "Verma",
        "jobs": [
            {
                "title": "Driver - airport drop",
                "description": "Pickup at 6 AM, drop at Terminal 2.",
                "customer_name": "Sunita Pillai",
                "customer_phone": "+91 90000 55555",
                "address": "9, Palm Meadows, Whitefield, Bengaluru 560066",
                "offset_hours": 3,
                "status": Job.Status.ASSIGNED,
            },
            {
                "title": "Gardening - monthly upkeep",
                "description": "Trim hedges, clear dry leaves.",
                "customer_name": "Arun Gupta",
                "customer_phone": "+91 90000 66666",
                "address": "44, Dollars Colony, RMV 2nd Stage, Bengaluru 560094",
                "offset_hours": 6,
                "status": Job.Status.ASSIGNED,
            },
        ],
    },
]


class Command(BaseCommand):
    help = "Create demo helpers and their assigned jobs (safe to re-run)."

    def handle(self, *args, **options):
        now = timezone.now()

        for helper_data in HELPERS:
            helper, created = User.objects.get_or_create(
                username=helper_data["username"],
                defaults={
                    "first_name": helper_data["first_name"],
                    "last_name": helper_data["last_name"],
                },
            )
            helper.set_password(DEMO_PASSWORD)
            helper.save()

            # Re-seeding resets job state so a demo always starts from a known place.
            helper.jobs.all().delete()
            for job_data in helper_data["jobs"]:
                Job.objects.create(
                    helper=helper,
                    title=job_data["title"],
                    description=job_data["description"],
                    customer_name=job_data["customer_name"],
                    customer_phone=job_data["customer_phone"],
                    address=job_data["address"],
                    scheduled_for=now + timedelta(hours=job_data["offset_hours"]),
                    status=job_data["status"],
                )

            label = "created" if created else "updated"
            self.stdout.write(
                self.style.SUCCESS(
                    f"{label} helper '{helper.username}' with {len(helper_data['jobs'])} jobs"
                )
            )

        if not User.objects.filter(username="admin").exists():
            User.objects.create_superuser("admin", "admin@example.com", DEMO_PASSWORD)
            self.stdout.write(self.style.SUCCESS("created superuser 'admin'"))

        self.stdout.write(self.style.SUCCESS(f"demo password for every account: {DEMO_PASSWORD}"))
