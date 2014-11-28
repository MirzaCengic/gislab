from django import forms

def create_case_insensitive_form(base_class):
	class FormClass(base_class):
		def __init__(self, data=None, **kwargs):
			if data:
				data = { k.lower(): v for k, v in data.iteritems() }
			super(FormClass, self).__init__(data=data, **kwargs)

		def _post_clean(self):
			super(FormClass, self)._post_clean()
			for key in self.cleaned_data.keys():
				value = self.cleaned_data[key]
				del self.cleaned_data[key]
				self.cleaned_data[key.upper()] = value
			print self.cleaned_data
	return FormClass

CaseInsensitiveForm = create_case_insensitive_form(forms.Form)
CaseInsensitiveModelForm = create_case_insensitive_form(forms.ModelForm)
