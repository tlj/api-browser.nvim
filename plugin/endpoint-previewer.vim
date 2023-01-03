command! EndpointRecents lua require("endpoint-previewer").recents()
command! EndpointEndpoints lua require("endpoint-previewer").endpoints()
command! EndpointAPI lua require("endpoint-previewer").select_api()
command! EndpointBaseUrl lua require("endpoint-previewer").select_base_url()
command! EndpointGoto lua require("endpoint-previewer").endpoint_with_urn()
command! EndpointRefresh lua require("endpoint-previewer").refresh_endpoints()

