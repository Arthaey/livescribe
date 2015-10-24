# livescribe

The [Livescribe](http://www.livescribe.com/) smartpen in a pretty cool tech toy, but it's not perfect, especially not for formatted output. This script treats Livescribe's OCR output as messy almost-Markdown, then emails or POSTs its cleaned up HTML to the destination of your choice.

Note: use at your own risk. I'm the only user of this script so far, so it's not entirely generic.

## Installation

* `git clone`
* `bundle install`

## Usage

```
Usage: mail_livescribe.rb [options]
    -d, --[no-]dry-run               Do not really send email
    -v, --[no-]verbose               Show verbose information
    -p, --[no-]print                 Print converted input
    -e, --[no-]email-input           Input is a forwarded email
    -t, --[no-]to EMAIL              To: email address
    -c, --[no-]cc EMAIL              Cc: email address
    -f, --[no-]from EMAIL            From: email address
    -u, --url URL                    Url to POST data to
```

See [settings.yml.template](https://github.com/Arthaey/livescribe/blob/master/settings.yml.template) for an example of the settings that are available.

## POST to a url

If using the "POST to a url" option, it can expect `snippet` to contain the HTML output and `is_html` to be `1`.
