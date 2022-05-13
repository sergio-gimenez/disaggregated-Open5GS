# Make WebUI accessible from the outside

By default, for security reasons, [the WebUI is accessible only from the host where open5gs is running itself](https://github.com/open5gs/open5gs/commit/608c08373de44b19afb0f76c986b713bb3fd6bb2). In order to be able to access the webui remotely, needs to be installed the following way:

```
curl https://raw.githubusercontent.com/sergio-gimenez/disaggregated-Open5GS/master/install_webui/install.sh | sudo -E bash -
```

I patched the installation in order to make the webui listen `0.0.0.0` instead of `127.0.0.1`.