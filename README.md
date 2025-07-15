# sky-carlock


# 🧩 Key Features
>- Lock/unlock vehicle with animation and sound
>- Vehicles can only be locked if they are owned by the player.
>- Horn sound and light effects when the key is opened/closed
>- Fake plate system: install and remove fake plates with animation
>- The `original_plate` item is automatically added when installing a fake plate.
>- Use items to restore the original plate

# 📦 Required Items

>**Add to `ox_inventory/data/items.lua`:**

>['fakeplate'] = {
  label = 'Fake Plate',
  weight = 200,
  stack = true,
  close = true,
  client = {
    export = 'sky-carlock.useFakePlate'
  }
},

>['original_plate'] = {
  label = 'Original Plate',
  weight = 200,
  stack = true,
  close = true,
  client = {
    export = 'sky-carlock.useOriginalPlate'
  }
},

>
>['lockpick'] = {
  label = 'Lockpick',
  weight = 100,
  stack = true,
  close = true,
  client = {
    export = 'sky-carlock.useLockpick'
  }
},

# 📁 Requirements
>- **[ox_lib]**
>- **[ox_inventory]**
>- **[oxmysql]**
>- **[es_extended]**
# 📃 License
**Free to use and modify. Credit is not required, but appreciated.**
