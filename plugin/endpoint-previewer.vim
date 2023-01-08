command! EndpointRecents lua require("endpoint-previewer").recents()
command! EndpointEndpoints lua require("endpoint-previewer").endpoints()
command! EndpointAPI lua require("endpoint-previewer").select_api()
command! EndpointSelectEnv lua require("endpoint-previewer").select_env()
command! EndpointSelectRemoteEnv lua require("endpoint-previewer").select_remote_env()
command! EndpointGoto lua require("endpoint-previewer").endpoint_with_urn()
command! EndpointRefresh lua require("endpoint-previewer").refresh_endpoints()

