from PIL import Image

from project.images import fill_square, limit_width


def make_image(width: int, height: int) -> Image.Image:
    return Image.new("RGB", (width, height))


def test_limit_width_scales_down_wide_images_keeping_aspect_ratio():
    # GIVEN an image wider than the limit
    img = make_image(3840, 2160)

    # WHEN it is resized
    resized = limit_width(1920)(img)

    # THEN it is exactly as wide as the limit with the same aspect ratio
    assert resized.size == (1920, 1080)


def test_limit_width_leaves_narrow_images_untouched():
    # GIVEN an image narrower than the limit
    img = make_image(800, 600)

    # WHEN it is resized
    resized = limit_width(1920)(img)

    # THEN nothing changes
    assert resized.size == (800, 600)


def test_fill_square_scales_large_avatars_to_the_short_side():
    # GIVEN an avatar larger than the limit on both sides
    img = make_image(2000, 1000)

    # WHEN it is resized
    resized = fill_square(512)(img)

    # THEN its short side matches the limit
    assert resized.size == (1024, 512)


def test_fill_square_leaves_small_avatars_untouched():
    # GIVEN an avatar within the limit
    img = make_image(300, 200)

    # WHEN it is resized
    resized = fill_square(512)(img)

    # THEN nothing changes
    assert resized.size == (300, 200)
