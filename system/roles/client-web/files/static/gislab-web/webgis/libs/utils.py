import urllib
from urlparse import parse_qs, urlsplit, urlunsplit


def secure_url(request, location=None):
	return request.build_absolute_uri(location).replace('http:', 'https:')

def set_query_parameters(url, params_dict):
	"""Given a URL, set or replace a query parameters and return the
	modified URL. Parameters are case insensitive.

	>>> set_query_parameters('http://example.com?foo=bar&biz=baz', {'foo': 'stuff'})
	'http://example.com?foo=stuff&biz=baz'

	"""
	url_parts = list(urlsplit(url))
	query_params = parse_qs(url_parts[3])

	params = dict(params_dict)
	new_params_names = [name.lower() for name in params_dict.iterkeys()]
	for name, value in query_params.iteritems():
		if name.lower() not in new_params_names:
			params[name] = value

	url_parts[3] = urllib.urlencode(params, doseq=True)
	return urlunsplit(url_parts)
