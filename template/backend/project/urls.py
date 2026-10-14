from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.contrib.staticfiles import views
from django.urls import path

from project.legal import legal_page

urlpatterns = [
    path("impressum", legal_page),
    path("privacy", legal_page, {"page": "privacy"}),
    path("admin/", admin.site.urls),
]

if settings.DEBUG:
    urlpatterns.append(path("static/<path:path>", views.serve))
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
