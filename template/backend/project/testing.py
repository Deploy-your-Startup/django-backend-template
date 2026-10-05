"""Helpers shared by the backend tests."""

import json
import shutil
import tempfile
from io import BytesIO

from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase, override_settings
from PIL import Image


def png_upload(width: int = 100, height: int = 100, name: str = "bild.png"):
    """A PNG with alpha channel, as a browser would upload it."""
    buffer = BytesIO()
    Image.new("RGBA", (width, height), (255, 0, 0, 128)).save(buffer, "PNG")
    return SimpleUploadedFile(name, buffer.getvalue(), content_type="image/png")


class MediaTestCase(TestCase):
    """TestCase that stores uploads in a temp directory, removed after each test."""

    def setUp(self):
        super().setUp()
        self.media_root = tempfile.mkdtemp()
        media = override_settings(MEDIA_ROOT=self.media_root)
        media.enable()
        self.addCleanup(media.disable)
        self.addCleanup(shutil.rmtree, self.media_root, True)


def toast(response) -> str:
    """The toast message an HTMX response triggers."""
    return json.loads(response["HX-Trigger"])["showMessage"]
