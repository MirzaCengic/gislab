from django.db import models
from django.conf import settings
from django.contrib.auth.models import AbstractUser


class GislabUser(AbstractUser):

	@classmethod
	def get_guest_user(cls):
		if getattr(settings, 'GISLAB_WEB_GUEST_USERNAME', None):
			if not hasattr(cls, 'guest_user'):
				guest_user = None
				try:
					guest_user = GislabUser.objects.get(username=settings.GISLAB_WEB_GUEST_USERNAME)
					guest_user.backend = "django.contrib.auth.backends.ModelBackend"
				except GislabUser.DoesNotExist:
					pass
				cls.guest_user = guest_user
			return cls.guest_user

	@property
	def is_guest(self):
		return self.username == getattr(settings, 'GISLAB_WEB_GUEST_USERNAME', '')

	def get_profile(self):
		return None

	def get_full_name(self):
		full_name = super(GislabUser, self).get_full_name()
		return full_name or self.username

	def __unicode__(self):
		return self.username


class Project_registry(models.Model):
	project = models.TextField(u"project", primary_key=True)
	gislab_version = models.CharField(u"gislab version", max_length=255)
	gislab_user = models.CharField(u"gislab user", max_length=255)
	gislab_unique_id = models.CharField(u"gislab unique id", max_length=255)
	publish_date = models.DateTimeField(u"publish date")
	last_display = models.DateTimeField(u"last display", auto_now=True)
