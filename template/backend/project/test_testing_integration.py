from django.http import HttpRequest, HttpResponse
from django.test import SimpleTestCase, override_settings
from django.urls import path

from project.htmx import respond
from project.testing import toast


def _toast_view(request: HttpRequest) -> HttpResponse:
    return respond(request, "Saved", "/")


urlpatterns = [path("toast-contract/", _toast_view)]


@override_settings(ROOT_URLCONF=__name__)
class ToastResponseIntegrationTests(SimpleTestCase):
    def test_reads_the_message_from_a_real_client_response(self):
        # GIVEN the real Django request handler and HTMX response helper
        client = self.client

        # WHEN an HTMX request reaches the view through Django's test client
        response = client.post("/toast-contract/", HTTP_HX_REQUEST="true")

        # THEN the typed toast helper accepts the response and reads its message
        self.assertEqual(response.status_code, 204)
        self.assertEqual(toast(response), "Saved")
