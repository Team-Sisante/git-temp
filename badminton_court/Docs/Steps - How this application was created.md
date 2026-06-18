# Steps - How this application was created.md

## Badminton Court Management Application - Implementation Guide

This document provides a step-by-step guide on creating a comprehensive badminton court management application using Python and Django. The application handles customer scheduling, fee monitoring, sales reporting, time warnings, and employee management.

### Table of Contents
1. [Project Setup](#1-project-setup)
2. [Django Project Creation](#2-django-project-creation)
3. [Database Models](#3-database-models)
4. [Admin Interface](#4-admin-interface)
5. [Customer Schedule and Fee Monitoring](#5-customer-schedule-and-fee-monitoring)
6. [Sales Report Generation](#6-sales-report-generation)
7. [Automatic Time Warnings](#7-automatic-time-warnings)
8. [Employee Management](#8-employee-management)
9. [Views and Templates](#9-views-and-templates)
10. [URL Configuration](#10-url-configuration)
11. [Background Tasks with Celery](#11-background-tasks-with-celery)
12. [Deployment Options](#12-deployment-options)

---

### 1. Project Setup

#### 1.1 Create Project Directory
```bash
mkdir badminton_court
cd badminton_court
```

#### 1.2 Create and Activate Virtual Environment
```bash
# Create virtual environment
python -m venv venv

# Activate virtual environment
# On Windows:
venv\Scripts\activate
# On Mac/Linux:
source venv/bin/activate
```

#### 1.3 Install Dependencies
```bash
# Install Django
pip install django

# Install additional required packages
pip install celery pandas matplotlib plotly django-celery-beat
```

#### 1.4 Create Requirements File
```bash
# Save all dependencies to requirements.txt
pip freeze > requirements.txt
```

Your `requirements.txt` should look something like this:
```
asgiref==3.7.2
billiard==3.6.4.0
celery==5.2.7
certifi==2022.12.7
charset-normalizer==3.1.0
Django==4.1.7
django-celery-beat==2.4.0
django-timezone-field==4.2.3
kombu==5.2.4
matplotlib==3.7.1
numpy==1.24.2
pandas==1.5.3
Pillow==9.4.0
plotly==5.14.1
python-dateutil==2.8.2
pytz==2022.7.1
six==1.16.0
sqlparse==0.4.3
tenacity==8.2.2
tzdata==2023.3
urllib3==1.26.15
vine==5.0.0
```

---

### 2. Django Project Creation

#### 2.1 Create Django Project
```bash
# Create Django project
django-admin startproject badminton_court .
```

#### 2.2 Create Django App
```bash
# Create the court management app
python manage.py startapp court_management
```

#### 2.3 Update Settings
Add your app to `badminton_court/settings.py`:
```python
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'court_management',  # Add this
    'django_celery_beat',  # Add this for Celery
]

# Add Celery configuration
CELERY_BROKER_URL = 'redis://localhost:6379'
CELERY_RESULT_BACKEND = 'redis://localhost:6379'
CELERY_ACCEPT_CONTENT = ['application/json']
CELERY_TASK_SERIALIZER = 'json'
CELERY_RESULT_SERIALIZER = 'json'
CELERY_TIMEZONE = TIME_ZONE
```

#### 2.4 Create Celery App
Create a new file `badminton_court/celery.py`:
```python
import os
from celery import Celery

# Set the default Django settings module for the 'celery' program.
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'badminton_court.settings')

app = Celery('badminton_court')

# Using a string here means the worker doesn't have to serialize
# the configuration object to child processes.
# - namespace='CELERY' means all celery-related configuration keys
#   should have a `CELERY_` prefix.
app.config_from_object('django.conf:settings', namespace='CELERY')

# Load task modules from all registered Django app configs.
app.autodiscover_tasks()
```

#### 2.5 Update __init__.py
Update `badminton_court/__init__.py`:
```python
# Import Celery app to ensure it's imported when Django starts
from .celery import app as celery_app

__all__ = ('celery_app',)
```

---

### 3. Database Models

Update `court_management/models.py` with the following models:

```python
from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator
from django.utils import timezone

class Customer(models.Model):
    name = models.CharField(max_length=100)
    email = models.EmailField(blank=True)
    phone = models.CharField(max_length=20)
    address = models.TextField(blank=True)
    membership_date = models.DateField(auto_now_add=True)
    active = models.BooleanField(default=True)
    
    def __str__(self):
        return self.name

class Court(models.Model):
    name = models.CharField(max_length=50)
    description = models.TextField(blank=True)
    hourly_rate = models.DecimalField(max_digits=10, decimal_places=2)
    active = models.BooleanField(default=True)
    
    def __str__(self):
        return self.name

class Booking(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('confirmed', 'Confirmed'),
        ('in_progress', 'In Progress'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    ]
    
    PAYMENT_STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('paid', 'Paid'),
        ('refunded', 'Refunded'),
    ]
    
    customer = models.ForeignKey(Customer, on_delete=models.CASCADE)
    court = models.ForeignKey(Court, on_delete=models.CASCADE)
    start_time = models.DateTimeField()
    end_time = models.DateTimeField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    fee = models.DecimalField(max_digits=10, decimal_places=2)
    payment_status = models.CharField(max_length=20, choices=PAYMENT_STATUS_CHOICES, default='pending')
    notes = models.TextField(blank=True)
    notified = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"{self.customer.name} - {self.court.name} ({self.start_time})"
    
    def duration_hours(self):
        return (self.end_time - self.start_time).total_seconds() / 3600

class Employee(models.Model):
    POSITION_CHOICES = [
        ('manager', 'Manager'),
        ('attendant', 'Attendant'),
        ('cleaner', 'Cleaner'),
        ('maintenance', 'Maintenance'),
    ]
    
    name = models.CharField(max_length=100)
    position = models.CharField(max_length=20, choices=POSITION_CHOICES)
    email = models.EmailField(blank=True)
    phone = models.CharField(max_length=20)
    address = models.TextField(blank=True)
    hire_date = models.DateField()
    hourly_rate = models.DecimalField(max_digits=10, decimal_places=2)
    active = models.BooleanField(default=True)
    
    def __str__(self):
        return f"{self.name} ({self.position})"

class WorkSchedule(models.Model):
    employee = models.ForeignKey(Employee, on_delete=models.CASCADE)
    date = models.DateField()
    start_time = models.TimeField()
    end_time = models.TimeField()
    notes = models.TextField(blank=True)
    
    def __str__(self):
        return f"{self.employee.name} - {self.date}"

class TimeEntry(models.Model):
    employee = models.ForeignKey(Employee, on_delete=models.CASCADE)
    clock_in = models.DateTimeField()
    clock_out = models.DateTimeField(null=True, blank=True)
    notes = models.TextField(blank=True)
    
    def __str__(self):
        return f"{self.employee.name} - {self.clock_in}"
    
    def duration_hours(self):
        if self.clock_out:
            return (self.clock_out - self.clock_in).total_seconds() / 3600
        return 0
    
    def calculate_pay(self):
        return self.duration_hours() * self.employee.hourly_rate

class Payment(models.Model):
    PAYMENT_METHOD_CHOICES = [
        ('cash', 'Cash'),
        ('card', 'Card'),
        ('online', 'Online'),
        ('other', 'Other'),
    ]
    
    booking = models.ForeignKey(Booking, on_delete=models.CASCADE)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    payment_method = models.CharField(max_length=10, choices=PAYMENT_METHOD_CHOICES)
    transaction_id = models.CharField(max_length=100, blank=True)
    payment_date = models.DateTimeField(auto_now_add=True)
    notes = models.TextField(blank=True)
    
    def __str__(self):
        return f"{self.booking} - {self.amount}"
```

#### 3.1 Create and Apply Migrations
```bash
python manage.py makemigrations
python manage.py migrate
```

---

### 4. Admin Interface

Update `court_management/admin.py` to register models with the admin interface:

```python
from django.contrib import admin
from .models import Customer, Court, Booking, Employee, WorkSchedule, TimeEntry, Payment

@admin.register(Customer)
class CustomerAdmin(admin.ModelAdmin):
    list_display = ('name', 'phone', 'email', 'membership_date', 'active')
    list_filter = ('active', 'membership_date')
    search_fields = ('name', 'phone', 'email')

@admin.register(Court)
class CourtAdmin(admin.ModelAdmin):
    list_display = ('name', 'hourly_rate', 'active')
    list_filter = ('active',)
    search_fields = ('name',)

@admin.register(Booking)
class BookingAdmin(admin.ModelAdmin):
    list_display = ('customer', 'court', 'start_time', 'end_time', 'status', 'payment_status', 'fee')
    list_filter = ('status', 'payment_status', 'court', 'start_time')
    search_fields = ('customer__name', 'court__name', 'notes')
    date_hierarchy = 'start_time'

@admin.register(Employee)
class EmployeeAdmin(admin.ModelAdmin):
    list_display = ('name', 'position', 'hourly_rate', 'hire_date', 'active')
    list_filter = ('position', 'active', 'hire_date')
    search_fields = ('name', 'phone', 'email')

@admin.register(WorkSchedule)
class WorkScheduleAdmin(admin.ModelAdmin):
    list_display = ('employee', 'date', 'start_time', 'end_time')
    list_filter = ('employee__position', 'date')
    search_fields = ('employee__name', 'notes')
    date_hierarchy = 'date'

@admin.register(TimeEntry)
class TimeEntryAdmin(admin.ModelAdmin):
    list_display = ('employee', 'clock_in', 'clock_out', 'duration_hours', 'calculate_pay')
    list_filter = ('employee__position', 'clock_in')
    search_fields = ('employee__name', 'notes')
    date_hierarchy = 'clock_in'

@admin.register(Payment)
class PaymentAdmin(admin.ModelAdmin):
    list_display = ('booking', 'amount', 'payment_method', 'payment_date')
    list_filter = ('payment_method', 'payment_date')
    search_fields = ('booking__customer__name', 'transaction_id', 'notes')
    date_hierarchy = 'payment_date'
```

---

### 5. Customer Schedule and Fee Monitoring

Create `court_management/views.py` with views for customer scheduling and fee monitoring:

```python
from django.shortcuts import render, get_object_or_404, redirect
from django.views.generic import ListView, DetailView, CreateView, UpdateView, DeleteView
from django.urls import reverse_lazy
from django.contrib import messages
from django.utils import timezone
from .models import Customer, Court, Booking, Payment
from .forms import BookingForm, PaymentForm
import pandas as pd
from django.http import HttpResponse

class BookingListView(ListView):
    model = Booking
    template_name = 'court_management/booking_list.html'
    context_object_name = 'bookings'
    
    def get_queryset(self):
        return Booking.objects.all().order_by('start_time')

class BookingDetailView(DetailView):
    model = Booking
    template_name = 'court_management/booking_detail.html'
    context_object_name = 'booking'

class BookingCreateView(CreateView):
    model = Booking
    form_class = BookingForm
    template_name = 'court_management/booking_form.html'
    success_url = reverse_lazy('booking-list')
    
    def form_valid(self, form):
        response = super().form_valid(form)
        messages.success(self.request, 'Booking created successfully!')
        return response

class BookingUpdateView(UpdateView):
    model = Booking
    form_class = BookingForm
    template_name = 'court_management/booking_form.html'
    success_url = reverse_lazy('booking-list')
    
    def form_valid(self, form):
        response = super().form_valid(form)
        messages.success(self.request, 'Booking updated successfully!')
        return response

class BookingDeleteView(DeleteView):
    model = Booking
    template_name = 'court_management/booking_confirm_delete.html'
    success_url = reverse_lazy('booking-list')
    
    def delete(self, request, *args, **kwargs):
        response = super().delete(request, *args, **kwargs)
        messages.success(self.request, 'Booking deleted successfully!')
        return response

def customer_booking_history(request, customer_id):
    customer = get_object_or_404(Customer, pk=customer_id)
    bookings = Booking.objects.filter(customer=customer).order_by('-start_time')
    
    context = {
        'customer': customer,
        'bookings': bookings,
    }
    return render(request, 'court_management/customer_booking_history.html', context)

def make_payment(request, booking_id):
    booking = get_object_or_404(Booking, pk=booking_id)
    
    if request.method == 'POST':
        form = PaymentForm(request.POST)
        if form.is_valid():
            payment = form.save(commit=False)
            payment.booking = booking
            payment.save()
            
            # Update booking payment status
            booking.payment_status = 'paid'
            booking.save()
            
            messages.success(request, 'Payment processed successfully!')
            return redirect('booking-detail', pk=booking.pk)
    else:
        form = PaymentForm(initial={'amount': booking.fee})
    
    context = {
        'form': form,
        'booking': booking,
    }
    return render(request, 'court_management/make_payment.html', context)
```

Create `court_management/forms.py` for forms:

```python
from django import forms
from .models import Booking, Payment, Customer, Court

class BookingForm(forms.ModelForm):
    class Meta:
        model = Booking
        fields = ['customer', 'court', 'start_time', 'end_time', 'fee', 'status', 'payment_status', 'notes']
        widgets = {
            'start_time': forms.DateTimeInput(attrs={'type': 'datetime-local'}),
            'end_time': forms.DateTimeInput(attrs={'type': 'datetime-local'}),
            'notes': forms.Textarea(attrs={'rows': 4}),
        }
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['customer'].queryset = Customer.objects.filter(active=True)
        self.fields['court'].queryset = Court.objects.filter(active=True)
    
    def clean(self):
        cleaned_data = super().clean()
        start_time = cleaned_data.get('start_time')
        end_time = cleaned_data.get('end_time')
        court = cleaned_data.get('court')
        
        if start_time and end_time and court:
            if start_time >= end_time:
                raise forms.ValidationError("End time must be after start time.")
            
            # Check for overlapping bookings
            overlapping_bookings = Booking.objects.filter(
                court=court,
                start_time__lt=end_time,
                end_time__gt=start_time,
                status__in=['confirmed', 'in_progress']
            )
            
            if self.instance:
                overlapping_bookings = overlapping_bookings.exclude(pk=self.instance.pk)
            
            if overlapping_bookings.exists():
                raise forms.ValidationError("This court is already booked for the selected time period.")
        
        return cleaned_data

class PaymentForm(forms.ModelForm):
    class Meta:
        model = Payment
        fields = ['amount', 'payment_method', 'transaction_id', 'notes']
        widgets = {
            'notes': forms.Textarea(attrs={'rows': 3}),
        }
```

---

### 6. Sales Report Generation

Add these views to `court_management/views.py`:

```python
from django.db.models import Sum, Count
from django.db.models.functions import TruncDate, TruncMonth
import matplotlib.pyplot as plt
import io
import base64
from datetime import datetime, timedelta

def sales_report(request):
    # Get date range from request or use default (last 30 days)
    end_date = timezone.now().date()
    start_date = request.GET.get('start_date')
    
    if start_date:
        start_date = datetime.strptime(start_date, '%Y-%m-%d').date()
    else:
        start_date = end_date - timedelta(days=30)
    
    # Get bookings within date range
    bookings = Booking.objects.filter(
        start_time__date__gte=start_date,
        start_time__date__lte=end_date
    )
    
    # Calculate total revenue
    total_revenue = bookings.aggregate(total=Sum('fee'))['total'] or 0
    
    # Calculate daily revenue
    daily_revenue = bookings.annotate(
        date=TruncDate('start_time')
    ).values('date').annotate(
        revenue=Sum('fee'),
        bookings_count=Count('id')
    ).order_by('date')
    
    # Calculate monthly revenue
    monthly_revenue = bookings.annotate(
        month=TruncMonth('start_time')
    ).values('month').annotate(
        revenue=Sum('fee'),
        bookings_count=Count('id')
    ).order_by('month')
    
    # Revenue by court
    court_revenue = bookings.values('court__name').annotate(
        revenue=Sum('fee'),
        bookings_count=Count('id')
    ).order_by('-revenue')
    
    # Revenue by payment method
    payment_method_revenue = Payment.objects.filter(
        booking__start_time__date__gte=start_date,
        booking__start_time__date__lte=end_date
    ).values('payment_method').annotate(
        revenue=Sum('amount'),
        payments_count=Count('id')
    ).order_by('-revenue')
    
    # Generate charts
    daily_chart = generate_line_chart(
        [item['date'].strftime('%Y-%m-%d') for item in daily_revenue],
        [float(item['revenue']) for item in daily_revenue],
        'Daily Revenue',
        'Date',
        'Revenue ($)'
    )
    
    court_chart = generate_bar_chart(
        [item['court__name'] for item in court_revenue],
        [float(item['revenue']) for item in court_revenue],
        'Revenue by Court',
        'Court',
        'Revenue ($)'
    )
    
    payment_chart = generate_pie_chart(
        [item['payment_method'] for item in payment_method_revenue],
        [float(item['revenue']) for item in payment_method_revenue],
        'Revenue by Payment Method'
    )
    
    context = {
        'start_date': start_date.strftime('%Y-%m-%d'),
        'end_date': end_date.strftime('%Y-%m-%d'),
        'total_revenue': total_revenue,
        'daily_revenue': daily_revenue,
        'monthly_revenue': monthly_revenue,
        'court_revenue': court_revenue,
        'payment_method_revenue': payment_method_revenue,
        'daily_chart': daily_chart,
        'court_chart': court_chart,
        'payment_chart': payment_chart,
    }
    
    return render(request, 'court_management/sales_report.html', context)

def generate_line_chart(x_data, y_data, title, x_label, y_label):
    plt.figure(figsize=(10, 6))
    plt.plot(x_data, y_data, marker='o')
    plt.title(title)
    plt.xlabel(x_label)
    plt.ylabel(y_label)
    plt.xticks(rotation=45)
    plt.tight_layout()
    
    # Convert plot to PNG image
    buffer = io.BytesIO()
    plt.savefig(buffer, format='png')
    buffer.seek(0)
    
    # Convert PNG image to base64 string
    image_png = buffer.getvalue()
    buffer.close()
    
    graphic = base64.b64encode(image_png)
    graphic = graphic.decode('utf-8')
    
    plt.close()
    
    return graphic

def generate_bar_chart(x_data, y_data, title, x_label, y_label):
    plt.figure(figsize=(10, 6))
    plt.bar(x_data, y_data)
    plt.title(title)
    plt.xlabel(x_label)
    plt.ylabel(y_label)
    plt.xticks(rotation=45)
    plt.tight_layout()
    
    # Convert plot to PNG image
    buffer = io.BytesIO()
    plt.savefig(buffer, format='png')
    buffer.seek(0)
    
    # Convert PNG image to base64 string
    image_png = buffer.getvalue()
    buffer.close()
    
    graphic = base64.b64encode(image_png)
    graphic = graphic.decode('utf-8')
    
    plt.close()
    
    return graphic

def generate_pie_chart(labels, data, title):
    plt.figure(figsize=(8, 8))
    plt.pie(data, labels=labels, autopct='%1.1f%%')
    plt.title(title)
    
    # Convert plot to PNG image
    buffer = io.BytesIO()
    plt.savefig(buffer, format='png')
    buffer.seek(0)
    
    # Convert PNG image to base64 string
    image_png = buffer.getvalue()
    buffer.close()
    
    graphic = base64.b64encode(image_png)
    graphic = graphic.decode('utf-8')
    
    plt.close()
    
    return graphic

def export_sales_report_csv(request):
    # Get date range from request or use default (last 30 days)
    end_date = timezone.now().date()
    start_date = request.GET.get('start_date')
    
    if start_date:
        start_date = datetime.strptime(start_date, '%Y-%m-%d').date()
    else:
        start_date = end_date - timedelta(days=30)
    
    # Get bookings within date range
    bookings = Booking.objects.filter(
        start_time__date__gte=start_date,
        start_time__date__lte=end_date
    )
    
    # Create DataFrame
    data = {
        'Booking ID': [booking.id for booking in bookings],
        'Customer': [booking.customer.name for booking in bookings],
        'Court': [booking.court.name for booking in bookings],
        'Start Time': [booking.start_time.strftime('%Y-%m-%d %H:%M') for booking in bookings],
        'End Time': [booking.end_time.strftime('%Y-%m-%d %H:%M') for booking in bookings],
        'Duration (hours)': [booking.duration_hours() for booking in bookings],
        'Fee': [float(booking.fee) for booking in bookings],
        'Payment Status': [booking.payment_status for booking in bookings],
        'Status': [booking.status for booking in bookings],
    }
    
    df = pd.DataFrame(data)
    
    # Create HTTP response with CSV data
    response = HttpResponse(content_type='text/csv')
    response['Content-Disposition'] = f'attachment; filename="sales_report_{start_date}_to_{end_date}.csv"'
    
    df.to_csv(path_or_buf=response, index=False)
    
    return response
```

---

### 7. Automatic Time Warnings

Create `court_management/tasks.py` for Celery tasks:

```python
from celery import shared_task
from django.core.mail import send_mail
from django.utils import timezone
from django.conf import settings
from .models import Booking
import logging

logger = logging.getLogger(__name__)

@shared_task
def check_booking_end_times():
    """
    Check for bookings that are ending soon and send notifications
    """
    now = timezone.now()
    threshold = now + timezone.timedelta(minutes=15)  # 15 minutes before end
    
    upcoming_end_bookings = Booking.objects.filter(
        end_time__lte=threshold,
        end_time__gt=now,
        status='in_progress',
        notified=False
    )
    
    for booking in upcoming_end_bookings:
        try:
            # Send email notification if customer has email
            if booking.customer.email:
                send_mail(
                    'Your booking time is ending soon',
                    f'Dear {booking.customer.name},\n\nYour booking at {booking.court.name} will end in 15 minutes at {booking.end_time.strftime("%Y-%m-%d %H:%M")}.\n\nPlease finish your game on time.\n\nThank you,\nBadminton Court Management',
                    settings.DEFAULT_FROM_EMAIL,
                    [booking.customer.email],
                    fail_silently=False,
                )
            
            # Mark booking as notified
            booking.notified = True
            booking.save()
            
            logger.info(f"Sent notification for booking {booking.id}")
        except Exception as e:
            logger.error(f"Error sending notification for booking {booking.id}: {str(e)}")
    
    return f"Processed {upcoming_end_bookings.count()} bookings"

@shared_task
def update_booking_status():
    """
    Update booking status based on current time
    """
    now = timezone.now()
    
    # Update bookings to 'in_progress' if start time has passed
    Booking.objects.filter(
        start_time__lte=now,
        end_time__gt=now,
        status='confirmed'
    ).update(status='in_progress')
    
    # Update bookings to 'completed' if end time has passed
    Booking.objects.filter(
        end_time__lte=now,
        status='in_progress'
    ).update(status='completed')
    
    return "Booking statuses updated"

@shared_task
def send_daily_report():
    """
    Send daily report to manager
    """
    today = timezone.now().date()
    tomorrow = today + timezone.timedelta(days=1)
    
    # Get today's bookings
    bookings = Booking.objects.filter(
        start_time__date=today
    )
    
    # Calculate statistics
    total_bookings = bookings.count()
    completed_bookings = bookings.filter(status='completed').count()
    total_revenue = bookings.aggregate(total=Sum('fee'))['total'] or 0
    
    # Get tomorrow's bookings
    tomorrow_bookings = Booking.objects.filter(
        start_time__date=tomorrow
    ).count()
    
    # Create report content
    report_content = f"""
    Daily Report - {today.strftime('%Y-%m-%d')}
    
    Today's Bookings: {total_bookings}
    Completed Bookings: {completed_bookings}
    Total Revenue: ${total_revenue}
    
    Tomorrow's Bookings: {tomorrow_bookings}
    """
    
    # Get manager email
    managers = Employee.objects.filter(position='manager', active=True)
    
    for manager in managers:
        if manager.email:
            try:
                send_mail(
                    f'Daily Report - {today.strftime("%Y-%m-%d")}',
                    report_content,
                    settings.DEFAULT_FROM_EMAIL,
                    [manager.email],
                    fail_silently=False,
                )
                logger.info(f"Sent daily report to {manager.name}")
            except Exception as e:
                logger.error(f"Error sending daily report to {manager.name}: {str(e)}")
    
    return "Daily report sent"
```

---

### 8. Employee Management

Add these views to `court_management/views.py`:

```python
from django.views.generic import ListView, DetailView, CreateView, UpdateView, DeleteView
from django.urls import reverse_lazy
from django.shortcuts import get_object_or_404, redirect
from django.contrib import messages
from django.utils import timezone
from .models import Employee, WorkSchedule, TimeEntry
from .forms import EmployeeForm, WorkScheduleForm, TimeEntryForm
from datetime import datetime, timedelta
import calendar

class EmployeeListView(ListView):
    model = Employee
    template_name = 'court_management/employee_list.html'
    context_object_name = 'employees'
    
    def get_queryset(self):
        return Employee.objects.filter(active=True)

class EmployeeDetailView(DetailView):
    model = Employee
    template_name = 'court_management/employee_detail.html'
    context_object_name = 'employee'

class EmployeeCreateView(CreateView):
    model = Employee
    form_class = EmployeeForm
    template_name = 'court_management/employee_form.html'
    success_url = reverse_lazy('employee-list')
    
    def form_valid(self, form):
        response = super().form_valid(form)
        messages.success(self.request, 'Employee created successfully!')
        return response

class EmployeeUpdateView(UpdateView):
    model = Employee
    form_class = EmployeeForm
    template_name = 'court_management/employee_form.html'
    success_url = reverse_lazy('employee-list')
    
    def form_valid(self, form):
        response = super().form_valid(form)
        messages.success(self.request, 'Employee updated successfully!')
        return response

class EmployeeDeleteView(DeleteView):
    model = Employee
    template_name = 'court_management/employee_confirm_delete.html'
    success_url = reverse_lazy('employee-list')
    
    def delete(self, request, *args, **kwargs):
        employee = self.get_object()
        employee.active = False
        employee.save()
        messages.success(request, 'Employee deactivated successfully!')
        return redirect('employee-list')

def employee_schedule(request, employee_id, year=None, month=None):
    employee = get_object_or_404(Employee, pk=employee_id)
    
    if year is None:
        year = timezone.now().year
    
    if month is None:
        month = timezone.now().month
    
    # Get work schedules for the month
    schedules = WorkSchedule.objects.filter(
        employee=employee,
        date__year=year,
        date__month=month
    ).order_by('date', 'start_time')
    
    # Get time entries for the month
    time_entries = TimeEntry.objects.filter(
        employee=employee,
        clock_in__year=year,
        clock_in__month=month
    ).order_by('clock_in')
    
    # Calculate total hours worked
    total_hours = sum(entry.duration_hours() for entry in time_entries if entry.clock_out)
    
    # Calculate total pay
    total_pay = sum(entry.calculate_pay() for entry in time_entries if entry.clock_out)
    
    # Create calendar
    cal = calendar.monthcalendar(year, month)
    
    # Create schedule dictionary for calendar
    schedule_dict = {}
    for schedule in schedules:
        day = schedule.date.day
        if day not in schedule_dict:
            schedule_dict[day] = []
        schedule_dict[day].append(schedule)
    
    # Create time entry dictionary for calendar
    time_entry_dict = {}
    for entry in time_entries:
        day = entry.clock_in.day
        if day not in time_entry_dict:
            time_entry_dict[day] = []
        time_entry_dict[day].append(entry)
    
    context = {
        'employee': employee,
        'year': year,
        'month': month,
        'month_name': calendar.month_name[month],
        'cal': cal,
        'schedules': schedules,
        'time_entries': time_entries,
        'total_hours': total_hours,
        'total_pay': total_pay,
        'schedule_dict': schedule_dict,
        'time_entry_dict': time_entry_dict,
        'prev_month': month - 1 if month > 1 else 12,
        'prev_year': year if month > 1 else year - 1,
        'next_month': month + 1 if month < 12 else 1,
        'next_year': year if month < 12 else year + 1,
    }
    
    return render(request, 'court_management/employee_schedule.html', context)

def clock_in(request, employee_id):
    employee = get_object_or_404(Employee, pk=employee_id)
    
    # Check if employee has an active time entry (clocked in but not out)
    active_entry = TimeEntry.objects.filter(
        employee=employee,
        clock_out__isnull=True
    ).first()
    
    if active_entry:
        messages.error(request, 'You are already clocked in!')
        return redirect('employee-detail', pk=employee.pk)
    
    # Create new time entry
    time_entry = TimeEntry.objects.create(
        employee=employee,
        clock_in=timezone.now(),
        notes=request.POST.get('notes', '')
    )
    
    messages.success(request, 'Clocked in successfully!')
    return redirect('employee-detail', pk=employee.pk)

def clock_out(request, employee_id):
    employee = get_object_or_404(Employee, pk=employee_id)
    
    # Find active time entry
    active_entry = TimeEntry.objects.filter(
        employee=employee,
        clock_out__isnull=True
    ).first()
    
    if not active_entry:
        messages.error(request, 'You are not clocked in!')
        return redirect('employee-detail', pk=employee.pk)
    
    # Update time entry
    active_entry.clock_out = timezone.now()
    active_entry.notes += f"\nClock out notes: {request.POST.get('notes', '')}"
    active_entry.save()
    
    messages.success(request, 'Clocked out successfully!')
    return redirect('employee-detail', pk=employee.pk)

def payroll_report(request, year=None, month=None):
    if year is None:
        year = timezone.now().year
    
    if month is None:
        month = timezone.now().month
    
    # Get all active employees
    employees = Employee.objects.filter(active=True)
    
    employee_data = []
    total_payroll = 0
    
    for employee in employees:
        # Get time entries for the month
        time_entries = TimeEntry.objects.filter(
            employee=employee,
            clock_in__year=year,
            clock_in__month=month,
            clock_out__isnull=False
        )
        
        # Calculate total hours and pay
        total_hours = sum(entry.duration_hours() for entry in time_entries)
        total_pay = sum(entry.calculate_pay() for entry in time_entries)
        
        employee_data.append({
            'employee': employee,
            'time_entries': time_entries,
            'total_hours': total_hours,
            'total_pay': total_pay,
        })
        
        total_payroll += total_pay
    
    context = {
        'year': year,
        'month': month,
        'month_name': calendar.month_name[month],
        'employee_data': employee_data,
        'total_payroll': total_payroll,
        'prev_month': month - 1 if month > 1 else 12,
        'prev_year': year if month > 1 else year - 1,
        'next_month': month + 1 if month < 12 else 1,
        'next_year': year if month < 12 else year + 1,
    }
    
    return render(request, 'court_management/payroll_report.html', context)
```

Create `court_management/forms.py` for employee forms (add to existing forms):

```python
# Add to existing forms.py

class EmployeeForm(forms.ModelForm):
    class Meta:
        model = Employee
        fields = ['name', 'position', 'email', 'phone', 'address', 'hire_date', 'hourly_rate', 'active']
        widgets = {
            'hire_date': forms.DateInput(attrs={'type': 'date'}),
            'address': forms.Textarea(attrs={'rows': 3}),
        }

class WorkScheduleForm(forms.ModelForm):
    class Meta:
        model = WorkSchedule
        fields = ['employee', 'date', 'start_time', 'end_time', 'notes']
        widgets = {
            'date': forms.DateInput(attrs={'type': 'date'}),
            'start_time': forms.TimeInput(attrs={'type': 'time'}),
            'end_time': forms.TimeInput(attrs={'type': 'time'}),
            'notes': forms.Textarea(attrs={'rows': 3}),
        }
    
    def clean(self):
        cleaned_data = super().clean()
        start_time = cleaned_data.get('start_time')
        end_time = cleaned_data.get('end_time')
        
        if start_time and end_time:
            if start_time >= end_time:
                raise forms.ValidationError("End time must be after start time.")
        
        return cleaned_data

class TimeEntryForm(forms.ModelForm):
    class Meta:
        model = TimeEntry
        fields = ['employee', 'clock_in', 'clock_out', 'notes']
        widgets = {
            'clock_in': forms.DateTimeInput(attrs={'type': 'datetime-local'}),
            'clock_out': forms.DateTimeInput(attrs={'type': 'datetime-local'}),
            'notes': forms.Textarea(attrs={'rows': 3}),
        }
    
    def clean(self):
        cleaned_data = super().clean()
        clock_in = cleaned_data.get('clock_in')
        clock_out = cleaned_data.get('clock_out')
        
        if clock_in and clock_out:
            if clock_in >= clock_out:
                raise forms.ValidationError("Clock out time must be after clock in time.")
        
        return cleaned_data
```

---

### 9. Views and Templates

Create basic templates in `court_management/templates/court_management/`:

#### 9.1 Base Template
Create `court_management/templates/court_management/base.html`:
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{% block title %}Badminton Court Management{% endblock %}</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.0/font/bootstrap-icons.css">
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-dark bg-dark">
        <div class="container">
            <a class="navbar-brand" href="{% url 'home' %}">Badminton Court Management</a>
            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
                <span class="navbar-toggler-icon"></span>
            </button>
            <div class="collapse navbar-collapse" id="navbarNav">
                <ul class="navbar-nav me-auto">
                    <li class="nav-item">
                        <a class="nav-link" href="{% url 'booking-list' %}">Bookings</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="{% url 'customer-list' %}">Customers</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="{% url 'court-list' %}">Courts</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="{% url 'employee-list' %}">Employees</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="{% url 'sales-report' %}">Sales Report</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="{% url 'payroll-report' %}">Payroll</a>
                    </li>
                </ul>
            </div>
        </div>
    </nav>

    <div class="container mt-4">
        {% if messages %}
            {% for message in messages %}
                <div class="alert alert-{{ message.tags }} alert-dismissible fade show" role="alert">
                    {{ message }}
                    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                </div>
            {% endfor %}
        {% endif %}

        {% block content %}{% endblock %}
    </div>

    <footer class="bg-dark text-white mt-5 py-3">
        <div class="container">
            <p class="text-center mb-0">Badminton Court Management System &copy; {% now "Y" %}</p>
        </div>
    </footer>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    {% block scripts %}{% endblock %}
</body>
</html>
```

#### 9.2 Index Template
Create `court_management/templates/court_management/index.html`:
```html
{% extends 'court_management/base.html' %}

{% block title %}Dashboard - Badminton Court Management{% endblock %}

{% block content %}
<div class="row">
    <div class="col-md-12">
        <h1>Dashboard</h1>
        <p class="lead">Welcome to the Badminton Court Management System</p>
    </div>
</div>

<div class="row mb-4">
    <div class="col-md-3">
        <div class="card bg-primary text-white">
            <div class="card-body">
                <h5 class="card-title">Today's Bookings</h5>
                <h2>{{ today_bookings|length }}</h2>
            </div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card bg-success text-white">
            <div class="card-body">
                <h5 class="card-title">Active Courts</h5>
                <h2>{{ active_courts }}</h2>
            </div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card bg-info text-white">
            <div class="card-body">
                <h5 class="card-title">Total Customers</h5>
                <h2>{{ total_customers }}</h2>
            </div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card bg-warning text-white">
            <div class="card-body">
                <h5 class="card-title">Active Employees</h5>
                <h2>{{ active_employees }}</h2>
            </div>
        </div>
    </div>
</div>

<div class="row">
    <div class="col-md-6">
        <div class="card">
            <div class="card-header">
                <h5>Today's Schedule</h5>
            </div>
            <div class="card-body">
                {% if today_bookings %}
                    <div class="table-responsive">
                        <table class="table table-striped">
                            <thead>
                                <tr>
                                    <th>Time</th>
                                    <th>Court</th>
                                    <th>Customer</th>
                                    <th>Status</th>
                                </tr>
                            </thead>
                            <tbody>
                                {% for booking in today_bookings %}
                                    <tr>
                                        <td>{{ booking.start_time|date:"H:i" }} - {{ booking.end_time|date:"H:i" }}</td>
                                        <td>{{ booking.court.name }}</td>
                                        <td>{{ booking.customer.name }}</td>
                                        <td>
                                            <span class="badge bg-{% if booking.status == 'confirmed' %}primary{% elif booking.status == 'in_progress' %}success{% elif booking.status == 'completed' %}secondary{% else %}danger{% endif %}">
                                                {{ booking.status }}
                                            </span>
                                        </td>
                                    </tr>
                                {% endfor %}
                            </tbody>
                        </table>
                    </div>
                {% else %}
                    <p>No bookings scheduled for today.</p>
                {% endif %}
            </div>
        </div>
    </div>
    <div class="col-md-6">
        <div class="card">
            <div class="card-header">
                <h5>Recent Activity</h5>
            </div>
            <div class="card-body">
                <ul class="list-group list-group-flush">
                    {% for activity in recent_activities %}
                        <li class="list-group-item d-flex justify-content-between align-items-center">
                            <div>
                                <strong>{{ activity.title }}</strong>
                                <br>
                                <small class="text-muted">{{ activity.description }}</small>
                            </div>
                            <small class="text-muted">{{ activity.timestamp|timesince }} ago</small>
                        </li>
                    {% empty %}
                        <li class="list-group-item">No recent activity.</li>
                    {% endfor %}
                </ul>
            </div>
        </div>
    </div>
</div>
{% endblock %}
```

#### 9.3 Booking Templates
Create `court_management/templates/court_management/booking_list.html`:
```html
{% extends 'court_management/base.html' %}

{% block title %}Bookings - Badminton Court Management{% endblock %}

{% block content %}
<div class="row mb-3">
    <div class="col-md-10">
        <h1>Bookings</h1>
    </div>
    <div class="col-md-2 text-end">
        <a href="{% url 'booking-create' %}" class="btn btn-primary">
            <i class="bi bi-plus-circle"></i> New Booking
        </a>
    </div>
</div>

<div class="card">
    <div class="card-body">
        <div class="table-responsive">
            <table class="table table-striped table-hover">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Customer</th>
                        <th>Court</th>
                        <th>Start Time</th>
                        <th>End Time</th>
                        <th>Status</th>
                        <th>Payment</th>
                        <th>Fee</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    {% for booking in bookings %}
                        <tr>
                            <td>{{ booking.id }}</td>
                            <td>{{ booking.customer.name }}</td>
                            <td>{{ booking.court.name }}</td>
                            <td>{{ booking.start_time|date:"Y-m-d H:i" }}</td>
                            <td>{{ booking.end_time|date:"Y-m-d H:i" }}</td>
                            <td>
                                <span class="badge bg-{% if booking.status == 'confirmed' %}primary{% elif booking.status == 'in_progress' %}success{% elif booking.status == 'completed' %}secondary{% else %}danger{% endif %}">
                                    {{ booking.status }}
                                </span>
                            </td>
                            <td>
                                <span class="badge bg-{% if booking.payment_status == 'paid' %}success{% elif booking.payment_status == 'pending' %}warning{% else %}danger{% endif %}">
                                    {{ booking.payment_status }}
                                </span>
                            </td>
                            <td>${{ booking.fee }}</td>
                            <td>
                                <div class="btn-group" role="group">
                                    <a href="{% url 'booking-detail' booking.pk %}" class="btn btn-sm btn-outline-primary">
                                        <i class="bi bi-eye"></i>
                                    </a>
                                    <a href="{% url 'booking-update' booking.pk %}" class="btn btn-sm btn-outline-secondary">
                                        <i class="bi bi-pencil"></i>
                                    </a>
                                    <a href="{% url 'booking-delete' booking.pk %}" class="btn btn-sm btn-outline-danger">
                                        <i class="bi bi-trash"></i>
                                    </a>
                                </div>
                            </td>
                        </tr>
                    {% empty %}
                        <tr>
                            <td colspan="9" class="text-center">No bookings found.</td>
                        </tr>
                    {% endfor %}
                </tbody>
            </table>
        </div>
    </div>
</div>
{% endblock %}
```

Create `court_management/templates/court_management/booking_form.html`:
```html
{% extends 'court_management/base.html' %}

{% block title %}{% if form.instance.pk %}Edit{% else %}Create{% endif %} Booking - Badminton Court Management{% endblock %}

{% block content %}
<div class="row">
    <div class="col-md-8 offset-md-2">
        <div class="card">
            <div class="card-header">
                <h4>{% if form.instance.pk %}Edit{% else %}Create{% endif %} Booking</h4>
            </div>
            <div class="card-body">
                <form method="post">
                    {% csrf_token %}
                    
                    {% if form.non_field_errors %}
                        <div class="alert alert-danger">
                            {{ form.non_field_errors }}
                        </div>
                    {% endif %}
                    
                    <div class="mb-3">
                        <label for="{{ form.customer.id_for_label }}" class="form-label">Customer</label>
                        {{ form.customer }}
                        {% if form.customer.errors %}
                            <div class="text-danger">{{ form.customer.errors }}</div>
                        {% endif %}
                    </div>
                    
                    <div class="mb-3">
                        <label for="{{ form.court.id_for_label }}" class="form-label">Court</label>
                        {{ form.court }}
                        {% if form.court.errors %}
                            <div class="text-danger">{{ form.court.errors }}</div>
                        {% endif %}
                    </div>
                    
                    <div class="row">
                        <div class="col-md-6 mb-3">
                            <label for="{{ form.start_time.id_for_label }}" class="form-label">Start Time</label>
                            {{ form.start_time }}
                            {% if form.start_time.errors %}
                                <div class="text-danger">{{ form.start_time.errors }}</div>
                            {% endif %}
                        </div>
                        
                        <div class="col-md-6 mb-3">
                            <label for="{{ form.end_time.id_for_label }}" class="form-label">End Time</label>
                            {{ form.end_time }}
                            {% if form.end_time.errors %}
                                <div class="text-danger">{{ form.end_time.errors }}</div>
                            {% endif %}
                        </div>
                    </div>
                    
                    <div class="row">
                        <div class="col-md-6 mb-3">
                            <label for="{{ form.fee.id_for_label }}" class="form-label">Fee ($)</label>
                            {{ form.fee }}
                            {% if form.fee.errors %}
                                <div class="text-danger">{{ form.fee.errors }}</div>
                            {% endif %}
                        </div>
                        
                        <div class="col-md-6 mb-3">
                            <label for="{{ form.status.id_for_label }}" class="form-label">Status</label>
                            {{ form.status }}
                            {% if form.status.errors %}
                                <div class="text-danger">{{ form.status.errors }}</div>
                            {% endif %}
                        </div>
                    </div>
                    
                    <div class="mb-3">
                        <label for="{{ form.payment_status.id_for_label }}" class="form-label">Payment Status</label>
                        {{ form.payment_status }}
                        {% if form.payment_status.errors %}
                            <div class="text-danger">{{ form.payment_status.errors }}</div>
                        {% endif %}
                    </div>
                    
                    <div class="mb-3">
                        <label for="{{ form.notes.id_for_label }}" class="form-label">Notes</label>
                        {{ form.notes }}
                        {% if form.notes.errors %}
                            <div class="text-danger">{{ form.notes.errors }}</div>
                        {% endif %}
                    </div>
                    
                    <div class="d-flex justify-content-between">
                        <a href="{% url 'booking-list' %}" class="btn btn-secondary">Cancel</a>
                        <button type="submit" class="btn btn-primary">Save</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>
{% endblock %}
```

Create `court_management/templates/court_management/booking_detail.html`:
```html
{% extends 'court_management/base.html' %}

{% block title %}Booking Details - Badminton Court Management{% endblock %}

{% block content %}
<div class="row mb-3">
    <div class="col-md-10">
        <h1>Booking Details</h1>
    </div>
    <div class="col-md-2 text-end">
        <a href="{% url 'booking-list' %}" class="btn btn-secondary">
            <i class="bi bi-arrow-left"></i> Back to List
        </a>
    </div>
</div>

<div class="card">
    <div class="card-body">
        <div class="row">
            <div class="col-md-6">
                <h4>Booking Information</h4>
                <table class="table table-borderless">
                    <tr>
                        <th style="width: 150px;">ID:</th>
                        <td>{{ booking.id }}</td>
                    </tr>
                    <tr>
                        <th>Customer:</th>
                        <td>{{ booking.customer.name }}</td>
                    </tr>
                    <tr>
                        <th>Court:</th>
                        <td>{{ booking.court.name }}</td>
                    </tr>
                    <tr>
                        <th>Start Time:</th>
                        <td>{{ booking.start_time|date:"Y-m-d H:i" }}</td>
                    </tr>
                    <tr>
                        <th>End Time:</th>
                        <td>{{ booking.end_time|date:"Y-m-d H:i" }}</td>
                    </tr>
                    <tr>
                        <th>Duration:</th>
                        <td>{{ booking.duration_hours|floatformat:1 }} hours</td>
                    </tr>
                    <tr>
                        <th>Status:</th>
                        <td>
                            <span class="badge bg-{% if booking.status == 'confirmed' %}primary{% elif booking.status == 'in_progress' %}success{% elif booking.status == 'completed' %}secondary{% else %}danger{% endif %}">
                                {{ booking.status }}
                            </span>
                        </td>
                    </tr>
                    <tr>
                        <th>Payment Status:</th>
                        <td>
                            <span class="badge bg-{% if booking.payment_status == 'paid' %}success{% elif booking.payment_status == 'pending' %}warning{% else %}danger{% endif %}">
                                {{ booking.payment_status }}
                            </span>
                        </td>
                    </tr>
                    <tr>
                        <th>Fee:</th>
                        <td>${{ booking.fee }}</td>
                    </tr>
                    <tr>
                        <th>Created:</th>
                        <td>{{ booking.created_at|date:"Y-m-d H:i" }}</td>
                    </tr>
                    <tr>
                        <th>Last Updated:</th>
                        <td>{{ booking.updated_at|date:"Y-m-d H:i" }}</td>
                    </tr>
                </table>
                
                {% if booking.notes %}
                    <h5>Notes</h5>
                    <p>{{ booking.notes }}</p>
                {% endif %}
            </div>
            
            <div class="col-md-6">
                <h4>Actions</h4>
                <div class="d-grid gap-2">
                    <a href="{% url 'booking-update' booking.pk %}" class="btn btn-primary">
                        <i class="bi bi-pencil"></i> Edit Booking
                    </a>
                    
                    {% if booking.payment_status != 'paid' %}
                        <a href="{% url 'make-payment' booking.pk %}" class="btn btn-success">
                            <i class="bi bi-credit-card"></i> Process Payment
                        </a>
                    {% endif %}
                    
                    <a href="{% url 'booking-delete' booking.pk %}" class="btn btn-danger">
                        <i class="bi bi-trash"></i> Delete Booking
                    </a>
                </div>
                
                <h4 class="mt-4">Customer Information</h4>
                <table class="table table-borderless">
                    <tr>
                        <th style="width: 150px;">Name:</th>
                        <td>{{ booking.customer.name }}</td>
                    </tr>
                    <tr>
                        <th>Phone:</th>
                        <td>{{ booking.customer.phone }}</td>
                    </tr>
                    {% if booking.customer.email %}
                        <tr>
                            <th>Email:</th>
                            <td>{{ booking.customer.email }}</td>
                        </tr>
                    {% endif %}
                    {% if booking.customer.address %}
                        <tr>
                            <th>Address:</th>
                            <td>{{ booking.customer.address }}</td>
                        </tr>
                    {% endif %}
                    <tr>
                        <th>Member Since:</th>
                        <td>{{ booking.customer.membership_date|date:"Y-m-d" }}</td>
                    </tr>
                </table>
                
                <div class="d-grid gap-2">
                    <a href="{% url 'customer-booking-history' booking.customer.pk %}" class="btn btn-outline-primary">
                        <i class="bi bi-calendar-history"></i> View Customer History
                    </a>
                </div>
            </div>
        </div>
    </div>
</div>

{% if booking.payment_set.all %}
    <div class="card mt-4">
        <div class="card-header">
            <h4>Payment History</h4>
        </div>
        <div class="card-body">
            <div class="table-responsive">
                <table class="table table-striped">
                    <thead>
                        <tr>
                            <th>Date</th>
                            <th>Amount</th>
                            <th>Method</th>
                            <th>Transaction ID</th>
                            <th>Notes</th>
                        </tr>
                    </thead>
                    <tbody>
                        {% for payment in booking.payment_set.all %}
                            <tr>
                                <td>{{ payment.payment_date|date:"Y-m-d H:i" }}</td>
                                <td>${{ payment.amount }}</td>
                                <td>{{ payment.get_payment_method_display }}</td>
                                <td>{{ payment.transaction_id|default:"-" }}</td>
                                <td>{{ payment.notes|default:"-" }}</td>
                            </tr>
                        {% endfor %}
                    </tbody>
                </table>
            </div>
        </div>
    </div>
{% endif %}
{% endblock %}
```

---

### 10. URL Configuration

Create `court_management/urls.py`:
```python
from django.urls import path
from . import views

urlpatterns = [
    # Home/Dashboard
    path('', views.index, name='home'),
    
    # Booking URLs
    path('bookings/', views.BookingListView.as_view(), name='booking-list'),
    path('bookings/<int:pk>/', views.BookingDetailView.as_view(), name='booking-detail'),
    path('bookings/create/', views.BookingCreateView.as_view(), name='booking-create'),
    path('bookings/<int:pk>/update/', views.BookingUpdateView.as_view(), name='booking-update'),
    path('bookings/<int:pk>/delete/', views.BookingDeleteView.as_view(), name='booking-delete'),
    path('bookings/<int:pk>/payment/', views.make_payment, name='make-payment'),
    
    # Customer URLs
    path('customers/', views.CustomerListView.as_view(), name='customer-list'),
    path('customers/<int:pk>/', views.CustomerDetailView.as_view(), name='customer-detail'),
    path('customers/create/', views.CustomerCreateView.as_view(), name='customer-create'),
    path('customers/<int:pk>/update/', views.CustomerUpdateView.as_view(), name='customer-update'),
    path('customers/<int:pk>/delete/', views.CustomerDeleteView.as_view(), name='customer-delete'),
    path('customers/<int:pk>/history/', views.customer_booking_history, name='customer-booking-history'),
    
    # Court URLs
    path('courts/', views.CourtListView.as_view(), name='court-list'),
    path('courts/<int:pk>/', views.CourtDetailView.as_view(), name='court-detail'),
    path('courts/create/', views.CourtCreateView.as_view(), name='court-create'),
    path('courts/<int:pk>/update/', views.CourtUpdateView.as_view(), name='court-update'),
    path('courts/<int:pk>/delete/', views.CourtDeleteView.as_view(), name='court-delete'),
    
    # Employee URLs
    path('employees/', views.EmployeeListView.as_view(), name='employee-list'),
    path('employees/<int:pk>/', views.EmployeeDetailView.as_view(), name='employee-detail'),
    path('employees/create/', views.EmployeeCreateView.as_view(), name='employee-create'),
    path('employees/<int:pk>/update/', views.EmployeeUpdateView.as_view(), name='employee-update'),
    path('employees/<int:pk>/delete/', views.EmployeeDeleteView.as_view(), name='employee-delete'),
    path('employees/<int:pk>/schedule/', views.employee_schedule, name='employee-schedule'),
    path('employees/<int:pk>/schedule/<int:year>/<int:month>/', views.employee_schedule, name='employee-schedule-month'),
    path('employees/<int:pk>/clock-in/', views.clock_in, name='employee-clock-in'),
    path('employees/<int:pk>/clock-out/', views.clock_out, name='employee-clock-out'),
    
    # Report URLs
    path('reports/sales/', views.sales_report, name='sales-report'),
    path('reports/sales/export/', views.export_sales_report_csv, name='export-sales-report'),
    path('reports/payroll/', views.payroll_report, name='payroll-report'),
    path('reports/payroll/<int:year>/<int:month>/', views.payroll_report, name='payroll-report-month'),
]
```

Update `badminton_court/urls.py`:
```python
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', include('court_management.urls')),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
```

---

### 11. Background Tasks with Celery

To run Celery, you need to have Redis installed and running. You can install Redis using:
```bash
# On Ubuntu/Debian
sudo apt-get install redis-server

# On Mac
brew install redis

# On Windows
# Download Redis from https://github.com/microsoftarchive/redis/releases
```

Start Redis server:
```bash
redis-server
```

In a separate terminal, start Celery worker:
```bash
celery -A badminton_court worker --loglevel=info
```

In another terminal, start Celery beat scheduler:
```bash
celery -A badminton_court beat --loglevel=info
```

To schedule the periodic tasks, add the following to `badminton_court/settings.py`:
```python
from datetime import timedelta

CELERY_BEAT_SCHEDULE = {
    'check-booking-end-times': {
        'task': 'court_management.tasks.check_booking_end_times',
        'schedule': 5.0,  # Run every 5 minutes
    },
    'update-booking-status': {
        'task': 'court_management.tasks.update_booking_status',
        'schedule': 10.0,  # Run every 10 minutes
    },
    'send-daily-report': {
        'task': 'court_management.tasks.send_daily_report',
        'schedule': {
            'hour': 18,  # Run at 6 PM every day
            'minute': 0,
        },
    },
}
```

---

### 12. Deployment Options

#### 12.1 Local Development
To run the application locally:
```bash
# Activate virtual environment
source venv/bin/activate  # or venv\Scripts\activate on Windows

# Run migrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser

# Run development server
python manage.py runserver
```

#### 12.2 Production Deployment

##### Option 1: PythonAnywhere (Free Tier)
1. Sign up for a PythonAnywhere account
2. Create a new Web app
3. Select Django as the framework
4. Upload your project files
5. Configure the WSGI file
6. Set up static files
7. Configure the database (PythonAnywhere provides MySQL)
8. Install dependencies using pip
9. Set up environment variables

##### Option 2: Heroku (Free Tier)
1. Sign up for a Heroku account
2. Install the Heroku CLI
3. Initialize a Git repository
4. Create a `Procfile` with:
   ```
   web: gunicorn badminton_court.wsgi
   worker: celery -A badminton_court worker --loglevel=info
   scheduler: celery -A badminton_court beat --loglevel=info
   ```
5. Create a `runtime.txt` with:
   ```
   python-3.10.6
   ```
6. Create a `requirements.txt` file
7. Add Django settings for Heroku
8. Deploy using Git:
   ```bash
   heroku login
   heroku create
   git push heroku main
   heroku run python manage.py migrate
   heroku run python manage.py createsuperuser
   heroku ps:scale worker=1 scheduler=1
   ```

##### Option 3: Self-Hosted
1. Set up a server (Ubuntu, CentOS, etc.)
2. Install Python, pip, virtualenv
3. Install and configure Nginx
4. Install and configure Gunicorn
5. Install and configure Redis
6. Set up a systemd service for Celery
7. Configure firewall settings
8. Set up SSL certificate (Let's Encrypt)

---

## Conclusion

This comprehensive badminton court management application provides all the functionality requested by your client:
1. Customer schedule and fee monitoring
2. Sales report generation
3. Automatic time warnings
4. Employee management with work schedules and payroll
5. All built using Python and Django

The application is free to set up and run, with options for deployment on various platforms. You can extend it further with additional features as needed.