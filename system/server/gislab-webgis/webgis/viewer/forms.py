from django import forms
#from django.forms.widgets import SelectMultiple


class MultipleStringsField(forms.CharField):
	"""Form field that accepts multiple values given as comma separated
	string (?param=val1,val2)."""

	#widget = SelectMultiple

	def to_python(self, value):
		if value:
			return [item.strip() for item in value.split(",")] # remove padding
		return []

class MultipleIntegersField(forms.CharField):
	"""Form field that accepts multiple integer values given as comma separated
	string (?param=val1,val2)."""

	#widget = SelectMultiple

	def to_python(self, value):
		if value:
			return [int(item) for item in value.split(",")] # remove padding
		return []

class ExtentField(forms.CharField):
	"""Form field representing extent area.

	Extent area is defined by 4 coordinates - coord1Min, coord2Min, coord1Max and coord2Max.
	Input is expecting to be a comma separated string, that will be converted to tuple of numbers.
	"""

	def validate(self, value):
		if value is not None and len(value) != 4:
			raise forms.ValidationError("BBOX must contain 4 coordinates!")

	def to_python(self, value):
		if value:
			try:
				coordinates = value.split(",")
				return map(float, coordinates)
			except:
				raise forms.ValidationError("Invalid BBOX value!")
		return None

class ViewerForm(forms.Form):
	project = forms.CharField(required=False)
	base = forms.CharField(required=False)
	overlay = forms.CharField(required=False)
	dpi = forms.IntegerField(required=False)
	scales = MultipleIntegersField(required=False)
	extent = ExtentField(required=False)
	drawings = MultipleStringsField(required=False)
