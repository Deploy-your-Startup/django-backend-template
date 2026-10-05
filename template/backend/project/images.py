import os
from collections.abc import Callable

from django.db.models.fields.files import FieldFile
from PIL import Image, ImageOps

Resize = Callable[[Image.Image], Image.Image]


def limit_width(max_width: int) -> Resize:
    """Scale down images wider than `max_width`, keeping the aspect ratio."""

    def resize(img: Image.Image) -> Image.Image:
        if img.width <= max_width:
            return img
        ratio = max_width / img.width
        return img.resize(
            (max_width, int(img.height * ratio)), Image.Resampling.LANCZOS
        )

    return resize


def fill_square(size: int) -> Resize:
    """Scale images exceeding `size` on any side (used for avatars)."""

    def resize(img: Image.Image) -> Image.Image:
        if img.width <= size and img.height <= size:
            return img
        ratio = max(size / img.width, size / img.height)
        new_size = (int(img.width * ratio), int(img.height * ratio))
        return img.resize(new_size, Image.Resampling.LANCZOS)

    return resize


def compress_to_jpeg(file: FieldFile, resize: Resize) -> str | None:
    """Re-encode an uploaded image as JPEG (85%) with EXIF orientation applied.

    Returns the new file name if the extension changed, otherwise None.
    """
    original_path = file.path
    img = Image.open(original_path)
    img = ImageOps.exif_transpose(img) or img
    img = resize(img)
    if img.mode in ("RGBA", "P"):
        img = img.convert("RGB")

    base, _ext = os.path.splitext(original_path)
    new_path = base + ".jpg"
    img.save(new_path, "JPEG", quality=85, optimize=True)

    if original_path == new_path:
        return None
    if os.path.exists(original_path):
        os.remove(original_path)
    return (file.name or "").rsplit(".", 1)[0] + ".jpg"
