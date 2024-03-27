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

## 3D axcera to coco cli:
```bash
swift run swift_coco --type 3D --axera-anno-path /data/dataset/aXcellent/manu-label/axera_manu_v1.0/ANNOTATION/ --axera-img-path /data/dataset/aXcellent/manu-label/axera_manu_v1.0/IMAGE/FRONT_rect --out-json-path /code/gaoyi_dataset/coco/aXcellent_CAR/annotations/axera2d_0124.json --scaling-type 3D --cam
era-yaml-path /code/gaoyi_dataset/sensors.yaml
```

```
car	2b2961a431b23c9007efe270c1d7eb79c19d4192d7cd2d924176eb0b19e7d2a1	1
truck	24611dec0a0a3ae6f9f3a63c27323a5615c029c22a8e472e2bc6ae3ca65a6293	2
cyclelist	eee7d058d1407d0b476963d43cd044209987be186fb28d5a703633bd55d43ed3	3
pedestrian	750cfe5c94c6b2f63d3b293bdf763cd678b99a0fada8cc984e5c046681b49057	4
tricycle	247a1cd4f4ac7b02c20b31fe458438cbdab6a13ff8b40fbaa6d2d7600bb4312d	5
bus	04e027e4990a203f4899f7e87c2d5ff6b9019e9565795619a59ce06c099560d4	6
bicycle	d29af8a2e160dd867fe45a75f70bf805b1b6c1cf92017cf53cdf1d5cf390c916	7
traffic	075f4ab854e2a33c8ac11c0758796af4ae994ec4e37e36b6f11b503492c68289	8
construction	7a01adea4b8a1084a7aebd7f3256080c31a3013aa5ad7638add2136d6f3e5371	9
others	01db91d06032cc64162c16f8e35725b0e632beebdde8b2c2459979d04fb1e20c	10
vehicle	b404ed3c370c8c264e53b1867929db93e94012bb618bb263f514e32fd9e5bc29	11
barrier	f0dc3075f012ecffa9225a29f5dda815bb4aac0c0f97edfb894152c1e7e0ec1d	12
portable	01e782826ae5182220bd6158f883d01ceb1bce659dc020e7c511f802a9aa7737	13
bendy	69a4fc72339ed264135236864a2c20d74cc8e8a87bd199f8e41dfba8615c15fa	14
RA_straight	c8c9b36dd59aad2e40a59df78b7f143ca16b14fb2169345023896b38d28cc2c5	15
RA_straight_right	bfd12aad78c5e9f4ed74c52bdd63105ddbca3c151d30f5f3a6bc532babe22365	16
RA_left	3284e6acaa0c40001de590789a918b2ebb6264f9d0e597952085fdbda6e025d5	17
stop_line	586e3a72234c910a8728987363317ee6f5f758e4e55d1d45e5d5571c4172d8ae	18
crosswalk	56421536c7a368a0bacb9fd125c0be4d96e187b3cbfa264cde540025e0efc865	19
RA_straight_left	dd564634cc41c695af3e3d8aa52e71f4a60df81d5220ec33c03963471ec8e1a2	20
RA_right	95ab273bfd3c028a43044d4749999bd2c5f6b740e00663699fe8acd67cc9158e	21
RA_left_right	fb23a29166c2f6f3d0d31f458da857bda6a3f43763c5cf23c5940d328f726a63	22
RA_u-turn	91b8f05e13d8eefb987ed3061568e6953c74a4a29768ecb3dbe870670b4222ea	23
RA_right_bend	0c1e10f3780e24d0a19369ae371fbae8a290fe05474af95208b29c94a84260ab	24
RA_left_bend	25ef19027755cdb52b545ba84eeea4821701df29e7d62343043a3cf0ec47cd52	25
RA_left_u-turn	6bacae4f1316cfcbf10d8a3dee512ba7ad6c1ef16df63937d47c462393cfaf7d	26
RA_straight_u-turn	85ebcbdf45012c79473600de6b99c0eb2579ec524dff7477f1a7209dc1fd3be4	27
TFL_red	ccbf596a4032cc173bd6bd58e84ece0021033216f0697216f90ffbb4a954a203	28
TFL_green	22b22910bc2dd34d0d9791e968fb63634bd13cccc3bf2c54b5510f87e1b97697	29
TFL_yellow	9abd69285c634186f124603ef566593a3d9bd6a52b29ed8e4102b0102ec43880	30
```

## Axera stage2 anno

```json
{
    "info": {
        "version": "1.0",
        "description": "Exported by --",
        "contributor": "appen",
        "date_created": "2024-03-17 09:48:27"
    },
    "licenses": {
        "name": "AXERA"
    },
    "categories": {
        "3d_bbox": [
            "obstacle"
        ],
        "rect": [
            "traffic_sign",
            "traffic_light",
            "road_arrow"
        ],
        "line": [
            "lane",
            "road_boundary",
            "stop_line",
            "cross_walk",
            "no_parking_area"
        ],
        "point": [
            "intersection"
        ]
    },
    "images": {
        "frame_name": "carid_1694143939.700131893",  #车辆id_frame名称
        "lidar_calibration": [],
        "cam_info": [
            {
                "frame_id": "FRONT",
                "width": 1920,
                "height": 1080,
                "calibration": []
            },
            {
                "frame_id": "FRONT_WIDE",
                "width": 3840,
                "height": 2160,
                "calibration": []
            },
            {
                "frame_id": "FISHEYE_FRONT",
                "width": 1920,
                "height": 1536,
                "calibration": []
            },
            {
                "frame_id": "FISHEYE_BACK",
                "width": 1920,
                "height": 1536,
                "calibration": []
            },
            {
                "frame_id": "FISHEYE_LEFT",
                "width": 1920,
                "height": 1536,
                "calibration": []
            },
            {
                "frame_id": "FISHEYE_RIGHT",
                "width": 1920,
                "height": 1536,
                "calibration": []
            },
            {
                "frame_id": "BACK",
                "width": 1920,
                "height": 1080,
                "calibration": []
            }
        ]
    },
    "annotations": {
        "obstacle": [
            {
                "id": 0,
                "category": "vehicle.car",
                "activity": "vehicle.moving",
                "visibility": "50% - 100%", #五个挡位：0， 0-30，30-50，50-100，100
                "pointCount": 231,
                "truncated": [],
                "position": { #3d box的中心点
                    "x": -12.850573251060737,
                    "y": 11.420862082071725,
                    "z": 0.7020549622294561
                },
                "dimension": {
                    "length": 4.469727993011474, # 长宽高
                    "width": 1.9089231491088876,
                    "height": 1.5610325266333185
                },
                "quaternion": {
                    "qx": -0.0011199000504199068, #四元数
                    "qy": 0.0011351155241995107,
                    "qz": 0.9998958063521571,
                    "qw": -0.014346908238134278
                },
				"taillight": { #取值范围 occlusion: true/false, status:true/false/unknown
					"left": {
						"occlusion": "true",
						"status": "true"
					},
					"right": {
						"occlusion": "true",
						"status": "true"
					},
					"brake": {
						"occlusion": "true",
						"status": "true"
					}

				},
				"wheel": {
					"left_front": {
						"occlusion": "true",  #驱逐范围：true/false/unknown
                        "bbox": [
                            {
                                "x": 1174.839192,  #左上角
                                "y": 526.069514
                            },
                            {
                                "x": 1194.839192,  #右下角
                                "y": 535.708251
                            }
                        ]
					},
					"left_middle": {
						"occlusion": "true",
                        "bbox": [
                            {
                                "x": 1174.839192, #左上角
                                "y": 526.069514
                            },
                            {
                                "x": 1194.839192, #右下角
                                "y": 535.708251
                            }
                        ]
					},
					"left_back": {
						"occlusion": "true",
                        "bbox": [
                            {
                                "x": 1174.839192, #左上角
                                "y": 526.069514
                            },
                            {
                                "x": 1194.839192, #右下角
                                "y": 535.708251
                            }
                        ]
					},
					"right_front": {
						"occlusion": "true",
                        "bbox": [
                            {
                                "x": 1174.839192, #左上角
                                "y": 526.069514
                            },
                            {
                                "x": 1194.839192, #右下角
                                "y": 535.708251
                            }
                        ]
					},
					"right_middle": {
						"occlusion": "true",
                        "bbox": [
                            {
                                "x": 1174.839192, #左上角
                                "y": 526.069514
                            },
                            {
                                "x": 1194.839192, #右下角
                                "y": 535.708251
                            }
                        ]
					},
					"right_back": {
						"occlusion": "true",
                        "bbox": [
                            {
                                "x": 1174.839192, #左上角
                                "y": 526.069514
                            },
                            {
                                "x": 1194.839192, #右下角
                                "y": 535.708251
                            }
                        ]
					}
				},
				"wheel_point": { #轮胎与地面的接触点，不计中间车轮
					"left_front": { #左前车轮
						"occlusion": "true",
						"point": {
							"x": 892.751734,
							"y": 453.177844
                 		}
					},
					"left_back": { #左后车轮
						"occlusion": "true",
						"point": {
							"x": 892.751734,
							"y": 453.177844
                 		}
					},
					"right_front": { #右前车轮
						"occlusion": "true",
						"point": {
							"x": 892.751734,
							"y": 453.177844
                 		}
					},
					"right_back": { #右后车轮
						"occlusion": "true",
						"point": {
							"x": 892.751734,
							"y": 453.177844
                 		}
					},
					"front": { #TODO :三轮车、二辆车的轮接点
						"occlusion": "true",
						"point": {
							"x": 892.751734,
							"y": 453.177844
                 		}
					},
					"back": { #TODO : 三轮车、二辆车的轮接点
						"occlusion": "true",
						"point": {
							"x": 892.751734,
							"y": 453.177844
                 		}
					}
				}
            }
        ],
        "traffic_sign": [
            {
                "id": 0, #字符串，或者有区分度就行
                "cam_name": "FRONT", #2D的cam_name取值范围都只有FRONT和FRONT_WIDE
                "category": "p40", #Axera规定的交通标志类型(见附录) + unknow
                "occlusion": 0,  #0或1
                "truncated": 0,  #0或1
                "bbox": [
                    {
                        "x": 1174.839192,
                        "y": 526.069514
                    },
                    {
                        "x": 1174.839192,
                        "y": 535.708251
                    }
                ]
            }
        ],
        "traffic_light": [
            {
                "id": 0, #如果是master-slave关系则有同样的id, 字符串，或者有区分度就行
                "master_slave": 1, # 0是master, 1是slave
                "cam_name": "FRONT", #2D的cam_name取值范围都只有FRONT和FRONT_WIDE
                "category": "light",  #Axera规定的交通类型 + unknow
                "occlusion": 0,
                "truncated": 0,
                "color": "green",  #类型red, yellow, green, black + unknow
                "direction": 0, #整型，0:面型行驶方向或者1：面向非行驶方向
                "bbox": [  #左上角，右下角
                    {
                        "x": 1174.839192,
                        "y": 526.069514
                    },
                    {
                        "x": 1174.839192,
                        "y": 535.708251
                    }
                ]
            }
        ],
        "road_arrow": [
            {
                "id": 0,
                "cam_name": "FRONT",
                "category": "left", #Axera规定的地面箭头类型, 见附录
                "occlusion": 0,
                "truncated": 0,
                "bbox": [ #左上角，右下角
                    {
                        "x": 1174.839192,
                        "y": 526.069514
                    },
                    {
                        "x": 1174.839192,
                        "y": 535.708251
                    }
                ]
            }
        ],
        "lane": [
            {
                "cam_name": "FRONT",
                "category": "solid", #Axera规定的车道线类型，见附录
                "color": "white", #取值范围：yellow, white，blue, unknown
				"lane_id": -1, #双线可以有相同的lane_id, 单线必须不同的lane_id
                "id": 3, #整形,字符串，或者有区分度就行
                "points": [ #不闭合线段
                    {
                        "x": 892.751734,
                        "y": 453.177844,
                        "z": 0,
                        "occ": 0 #取值范围[0, 1, 2, 3, 4]
                    },
                    {
                        "x": 911.266689,
                        "y": 453.177844,
                        "z": 0,
                        "occ": 1 #取值范围[0, 1, 2, 3, 4]
                    },
                    {
                        "x": 911.266689,
                        "y": 473.302795,
                        "z": 0,
                        "occ": 1 #取值范围[0, 1, 2, 3, 4]
                    },
                    {
                        "x": 892.751734,
                        "y": 473.302795,
                        "z": 0,
                        "occ": 1 #取值范围[0, 1, 2, 3, 4]
                    }
                ]
            }
        ],
        "road_boundary": [  #不闭合线段
            {
                "cam_name": "FRONT",
                "id": -1,  #整形,字符串，或者有区分度就行
				"texture": "grassland", #取值范围:见附录3
                "points": [
                    {
                        "x": 892.751734,
                        "y": 453.177844,
                        "z": 0,
                        "occ": 0 #取值范围[0, 1, 2, 3]
                    },
                    {
                        "x": 911.266689,
                        "y": 453.177844,
                        "z": 0,
                        "occ": 1 #取值范围[0, 1, 2, 3]
                    },
                    {
                        "x": 911.266689,
                        "y": 473.302795,
                        "z": 0,
                        "occ": 1 #取值范围[0, 1, 2, 3]
                    },
                    {
                        "x": 892.751734,
                        "y": 473.302795,
                        "z": 0,
                        "occ": 1 #取值范围[0, 1, 2, 3]
                    }
                ]
            }
        ],
        "stop_line": [
            {
                "cam_name": "FRONT",
                "id": 2,
                "points": [
                    {
                        "x": 892.751734,
                        "y": 453.177844,
                        "z": 0,
                        "occ": 0 #取值范围[0, 1, 2, 3]
                    },
                    {
                        "x": 911.266689,
                        "y": 453.177844,
                        "z": 0,
                        "occ": 1 #取值范围[0, 1, 2, 3]
                    },
                    {
                        "x": 911.266689,
                        "y": 473.302795,
                        "z": 0,
                        "occ": 1 #取值范围[0, 1, 2, 3]
                    },
                    {
                        "x": 892.751734,
                        "y": 473.302795,
                        "z": 0,
                        "occ": 1 #取值范围[0, 1, 2, 3]
                    }
                ]
            }
        ],
        "cross_walk": [ #闭合多边形
            {
                "cam_name": "FRONT",
                "id": 1,
                "points": [
                    {
                        "x": 892.751734,
                        "y": 453.177844,
                        "z": 0,
                        "occ": 0 #取值范围[0, 1, 2, 3]
                    },
                    {
                        "x": 911.266689,
                        "y": 453.177844,
                        "z": 0,
                        "occ": 1 #取值范围[0, 1, 2, 3]
                    },
                    {
                        "x": 911.266689,
                        "y": 473.302795,
                        "z": 0,
                        "occ": 1 #取值范围[0, 1, 2, 3]
                    },
                    {
                        "x": 892.751734,
                        "y": 473.302795,
                        "z": 0,
                        "occ": 1 #取值范围[0, 1, 2, 3]
                    }
                ]
            }
        ],
        "no_parking_area": [ #闭合多边形
            {
                "cam_name": "FRONT",
                "id": 1,
                "points": [
                    {
                        "x": 892.751734,
                        "y": 453.177844,
                        "z": 0,
                        "occ": 0 #取值范围[0, 1, 2, 3]
                    },
                    {
                        "x": 911.266689,
                        "y": 453.177844,
                        "z": 0,
                        "occ": 1 #取值范围[0, 1, 2, 3]
                    },
                    {
                        "x": 911.266689,
                        "y": 473.302795,
                        "z": 0,
                        "occ": 1 #取值范围[0, 1, 2, 3]
                    },
                    {
                        "x": 892.751734,
                        "y": 473.302795,
                        "z": 0,
                        "occ": 1  #取值范围[0, 1, 2, 3]
                    }
                ]
            }
        ],
        "intersection": [
            {
                "cam_name": "FRONT",
                "id": 0, #能区分就行
                "category": "split_point", #取值范围["split_point", "conflux_point"]
                "points": {
                        "x": 892.751734,
                        "y": 453.177844
                },
				"constitute": ["-1", "-2"] #两条lane_id(必须对应lane标注里面有的id)， 用于指示交叉的线段
            }
        ]
    }
}
```
