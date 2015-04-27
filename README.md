# elastex - _le_ elastic exporter

We often needed to export raw source data from our Elasticsearch cluster. As the size of stored data grew, the `curl` command stolen from Kibana 3 via its inspect function to do this became more and more suboptimal. There are similar tools to run queries against an Elasticsearch cluster, but none of them seemed to have all the functionality we wanted to use while usually being more complex than we wanted. We needed something that:

- uses the scan and scroll technique to retrieve data
- optionally supports hourly index patterns
- can show its progress
- both ends of a time range can be specified

So at least until we can send pull requests for other tools to implement those, we decided to just quickly roll our own.
