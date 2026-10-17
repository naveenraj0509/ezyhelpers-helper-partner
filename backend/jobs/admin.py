from django.contrib import admin

from .models import Job


@admin.register(Job)
class JobAdmin(admin.ModelAdmin):
    list_display = ("title", "helper", "customer_name", "scheduled_for", "status")
    list_filter = ("status", "helper")
    search_fields = ("title", "customer_name", "address")
