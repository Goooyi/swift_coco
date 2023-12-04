# swift_coco
Map axera json annotation format toto coco annotation format

## Installation
[Install](https://www.swift.org/install/) swift 5.8.1 or use the devcontainer settings in this code base.

## Package used?
None. Since swift package [SwiftyJson](https://swiftpackageindex.com/SwiftyJSON/SwiftyJSON) not compitable with Linux for now, so write entirely using swift natively on Linux [JSONDecoder](https://developer.apple.com/documentation/foundation/jsondecoder).

## Usage

Example

```bash
swift run swift_coco --type 2D --axera-anno-path axera_anno/root1/ --axera-anno-path axera_anno/root2/ --axera-img-path /example/axera_img/root --out-json-path out.json
```

## TODO

- [ ] Image `id` filed is mapped to it's index on the `images` fileds, so mergeing with other source annotated `.json` file may cause conflict
- [x] `file_name` in the image name is named as absolute path since images can locate at different directories.
- [ ] split train/val/test :

## Notice

1. coco format set category id=0 as `background` class. When training with [detectron2](https://github.com/facebookresearch/detectron2) framework, the totoal class param in your config should be set to total_class_num + 1(background class)
1. totoal number of class is determined at run time, according to the given axera anno json file. So if an category is not present in original axera anno, it will not present in coco anno.
1. To ensure consistant category2id mapping, SHA256 hashmap is used and save in `./Config/categroy2id_hashmap.txt`. If the traning framework like detectron2 force the category-id do not surpass the totoal amount of categories available in the annotations(e.g. total 80 categories, but the dog category has an id 80(the most great id is supposed to be 79)), user should modify there own coco-json annotation.

## Reference: Structure of coco format
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
            "bbox": [260, 177, 231, 199], //[left_top_x, left_top_y, width, height]
            "segmentation": [...],
            "area": 45969, // bbox width * height
            "iscrowd": 0
        },
        ...
    ]
}
```