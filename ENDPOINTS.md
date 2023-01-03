# Endpoints specification

```javascript
{
  "apis": [
    "dessert place v1": {
      "endpoints": [
        {
          "url": "/{package}/{version}/{lang}/desserts.json"
        },
        {
          "url": "/{package}/{version}/{lang}/dessert/{desertId}.json"
        }
      ],
      "requirements": {
        "package": "^dessertplace$",
        "version": "^v1$",
        "dessertId": "^dessert:\\d+$"
      }
    },
    "bike store v1": {
      "endpoints": [
        {
          "url": "/{package}/{version}/{lang}/bikes.{format}"
        },
        {
          "url": "/{package}/{version}/{lang}/bike/{bikeId}.{format}"
        },
      ],
      "requirements": {
        "package": "^bikestore$",
        "version": "^v1$",
        "bikeId": "^bike:\\d+$"
      },
      "defaults": {
        "package": ["bikestore"],
        "version": ["v1"]
      }
    }
  ],
  "global": {
    "endpoints": [
      {
        "url": "/global/{globalId}.{format}",
      }
    ],
    "requirements": {
      "lang": "^[a-z]+$",
      "globalId": "^global:\\d+$",
      "format": "^(json|xml)$"
    },
    "defaults": {
      "lang": ["en"],
      "format": ["json", "xml"]
    }
  }
}
```
