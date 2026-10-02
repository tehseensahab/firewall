{{- $cat := "" }}{{ with .GetTerms "categories" }}{{ $cat = (index . 0).LinkTitle }}{{ end -}}
# {{ .Title }}

{{ with .Params.summary | default .Description }}> {{ . }}

{{ end -}}
- URL: {{ .Permalink }}
- Site: {{ site.Title }} ({{ site.Home.Permalink }})
{{- with $cat }}
- Topic: {{ . }}
{{- end }}
{{- if eq .Type "posts" }}
{{- with .Params.tags }}
- Tags: {{ delimit . ", " }}
{{- end }}
- Published: {{ .Date.Format "2006-01-02" }}
{{- if ne (.Lastmod.Format "2006-01-02") (.Date.Format "2006-01-02") }}
- Updated: {{ .Lastmod.Format "2006-01-02" }}
{{- end }}
- Author: {{ .Params.author | default site.Params.author }}
{{- end }}
{{- with .Params.takeaways }}

## Key takeaways

{{ range . }}- {{ . }}
{{ end }}
{{- end }}

{{ .RawContent | chomp }}
{{- with .Params.faq }}

## Frequently asked questions
{{ range . }}
### {{ .q }}

{{ .a }}
{{ end }}
{{- end }}
{{- with .Params.imageCredit }}

Image credit: {{ . }}
{{- end }}
