command! SapiRecents lua require("sapi-preview").recents()
command! SapiEndpoints lua require("sapi-preview").endpoints()
command! SapiPackage lua require("sapi-preview").select_package()
command! SapiBaseUrl lua require("sapi-preview").select_base_url()
command! SapiGoto lua require("sapi-preview").endpoint_with_urn()
command! SapiRefresh lua require("sapi-preview").refresh_endpoints()

