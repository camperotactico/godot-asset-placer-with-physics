# Asset Placer with Physics ![Asset Icon](./addons/asset_placer_with_physics/icons/Falling3DAssetIcon.svg)
[![Made with Godot](https://img.shields.io/badge/Made%20with-Godot-478CBF?style=flat&logo=godot%20engine&logoColor=white)](https://godotengine.org)
![Mastodon Follow](https://img.shields.io/mastodon/follow/109780053447231118?domain=mastodon.gamedev.place)


An editor plugin that allows any `Node3D` derived `PackedScene` to be instantiated and placed in a 3D scene using physics. 

This tool is useful to automatically place assets that need to lay naturally on the ground, or against other assets.

## ⬇️ Installation
1. Download the asset from the `AssetLib` tab in the Godot Editor.
2. Enable the plugin `Project` -> `Project Settings` -> `Plugins` -> `AssetPlacerWithPhysics` 

## 📖 Usage 
1. Open the scene you want to place assets into.
2. Add a new ![Asset Icon](./addons/asset_placer_with_physics/icons/Falling3DAssetIcon.svg)`AssetPlacerWithPhysicsNode` to the tree. Place it at ground level near the area you want to place assets in.
3. Add the `PackedScene` asset you want to spawn to the `Asset Packed Scene` field in the inspector. 

> A copy of the asset will appear on the screen where the ![Asset Icon](./addons/asset_placer_with_physics/icons/Falling3DAssetIcon.svg)`AssetPlacerWithPhysicsNode` was placed.  This instance helps preview how the asset is going to look and how high from the ground level it will spawn.

4. Modify the value of `Spawned Asset Height` to change how high the instances of the asset will spawn from.
5. In the `Asset Shape 3D` field in the inspector, create or load a `Shape3D` that best matches the asset that is going to be spawned.  This shape is going to be used for collisions while the asset is placed on the scene.
6. Set the `Asset Collision Layer` and `Asset Collision Mask` fields on the inspector. These values determine which `Physics3D` layers the spawned assets belong to and which ones they can collide with. If unsure, leave the default values.

> Even when the asset to spawn already moves with physics or has its own collisions, it is disabled when spawned and wrapped inside a custom `RigidBody3D` to allow any asset to be compatible. Because of that, a `Shape3D`, collision layers, and collision masks need to be provided as well.

7. In the `Spawned Assets Parent` field in the inspector, chose a node to be used as parent of all the instances of the asset.
8. Set a key to be used as button to spawn copies of the asset in the `Spawn Asset Key` field in the inspector.
9. Enable this ![Asset Icon](./addons/asset_placer_with_physics/icons/Falling3DAssetIcon.svg)`AssetPlacerWithPhysicsNode`  by setting the `Enable` field to true. Press the assigned key to start placing assets. 
    
> Play around with the rest of the inspector fields to change how the spawning system works.


## 🧰 Features
- Compatible with any `Node3D` asset, even if they don't include `CollisionShape3D` or `PhysicsBody3D`
- Collision layers and masks can be used to filer which elements interact with the spawned assets.
- Integrated with the Godot editor's undo-redo system.

## 🐛 Limitations, known issues, bugs
- It is recommended to wait until all the spawned instances are added to the tree (confirmation messages can be seen in the `Output` bottom panel) before:
    1. Closing, saving, modifying or switching the opened scene
	2. Performing undo or redo commands
