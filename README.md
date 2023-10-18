# swift_coco

## Package used?
swift package [SwiftyJson](https://swiftpackageindex.com/SwiftyJSON/SwiftyJSON) not compitable with Linux for now, so write entirely using swift natively on Linux [JSONDecoder](https://developer.apple.com/documentation/foundation/jsondecoder).

## TODO

- [ ] Since image `id` filed is mapped to it's index on the `images` fileds, mergeing with other source annotated `.json` file is not checked

- [ ] `file_name` in the image name is named as absolute path since images can locate at different directories.


## Structure of coco format
```json
{
    "info": {
        "year": "2023",
        "version": "0.1",
        "description": "Exported by Swift_COCO",
        "contributor": "gaoyi",
        "url": "",
        "date_created": "2023-10-17T09:48:27"
    },
    "licenses": [
        {
          "url": "",
          "id": 1,
          "name": ""
        },
        ...
    ],
    "categories": [
        ...
        {
            "id": 2,
            "name": "cat",
            "supercategory": "animal"
        },
        ...
    ],
    "images": [
        {
            "id": 0,
            "license": 1,
            "file_name": "<filename0>.<ext>",
            "height": 480,
            "width": 640,
            "date_captured": null
        },
        ...
    ],
    "annotations": [
        {
            "id": 0,
            "image_id": 0,
            "category_id": 2,
            "bbox": [260, 177, 231, 199],
            "segmentation": [...],
            "area": 45969,
            "iscrowd": 0
        },
        ...
    ]
}
```