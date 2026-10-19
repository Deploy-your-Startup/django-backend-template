# Security before public sharing

Check these before a release is shared publicly. Local tests do not replace a
check of the live deployment.

- Test anonymous and other-account access to private data and every write; keep
  ownership checks server-side and CSRF protection on cookie-authenticated writes.
- Bound uploads (bytes, count, pixels), stored data and paid API usage per user;
  rate-limit login and registration where the app handles credentials.
- Verify production HTTPS, Secure/HttpOnly session cookies and HSTS through the
  actual ingress; trust forwarded headers only from the trusted proxy.
- Before declaring a launch complete, verify live CSS/JS and a core user flow;
  HTTP 200 alone is insufficient.
- Public links expose only explicitly approved data, never login identities,
  secrets or source uploads. `noindex` is not access control.

Django session login needs production `SESSION_COOKIE_SECURE` and
`CSRF_COOKIE_SECURE`, plus login throttling; framework defaults are insufficient.
