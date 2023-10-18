# swift_coco

## Installation
[Install](https://www.swift.org/install/) swift 5.8.1

## Package used?
None. Since swift package [SwiftyJson](https://swiftpackageindex.com/SwiftyJSON/SwiftyJSON) not compitable with Linux for now, so write entirely using swift natively on Linux [JSONDecoder](https://developer.apple.com/documentation/foundation/jsondecoder).

## TODO

- [ ] fixed id2category mapping
- [ ] Image `id` filed is mapped to it's index on the `images` fileds, so mergeing with other source annotated `.json` file may cause conflict
- [ ] `file_name` in the image name is named as absolute path since images can locate at different directories.
- [ ] split train/val/test :
- [x] For the purpose of continue training of models with new data, fix categoryid2name mapping by an config `.txt` file

## Notice

1. coco format set category id=0 as `background` class. When training with [detectron2](https://github.com/facebookresearch/detectron2) framework, the totoal class param in your config should be set to total_class_num + 1(background class)
1. totoal number of class is determined at run time, according to the given axera anno json file. So if an category is not present in original axera anno, it will not present in coco anno.(TODO: fixed id2category mapping)
1. id to name mapping format in the .txt file:
`A B C`, A is the categoryID, B is the `categoryName` field in the axera anno(为中文字符), C is the uft8 string that represent the category used by coco anno.
e.g.
```txt
0 背景 background
1 路面箭头 Road_Arrow
2 人行横道 Crosswalk
3 停止线 Stop-line
```

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