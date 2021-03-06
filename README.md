# elastex - _le_ elastic exporter

We often needed to export raw source data from our Elasticsearch cluster. As the size of stored data grew, the `curl` command stolen from Kibana 3 via its inspect function to do this became more and more suboptimal. There are similar tools to run queries against an Elasticsearch cluster, but none of them seemed to have all the functionality we wanted to use while usually being more complex than we wanted. We needed something that:

- uses the scan and scroll technique to retrieve data
- optionally supports hourly index patterns
- can show its progress
- both ends of a time range can be specified

So at least until we can send pull requests for other tools to implement those, we decided to just quickly roll our own.

## Installation

elastex can be installed directly from the repository with [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla) and [cpanm](https://metacpan.org/pod/App::cpanminus):

 1. `dzil authordeps --missing | cpanm`
 2. `dzil install`

## Built-in help

If you need to quickly check what commands and options are there, just use the built-in help system:

`elastex help`

Or for a specific command:

`elastex help command`
