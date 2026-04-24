class ARMockData {
  static Map<String, String> getObjectInfo(String objectName) {
    final key = objectName.toLowerCase();
    
    for (var entry in objects.entries) {
      if (key.contains(entry.key.toLowerCase()) || entry.key.toLowerCase().contains(key)) {
        return entry.value;
      }
    }
    
    return {
      'CATEGORY': 'Unknown Object',
      'STATUS': 'Unidentified',
      'INFO': 'No data available in current databanks.',
    };
  }

  static const Map<String, Map<String, String>> objects = {
    'Pen': {'CATEGORY': 'Stationery', 'TYPE': 'Writing Tool', 'INFO': 'Dispenses ink for writing or drawing.', 'MATERIAL': 'Plastic/Metal'},
    'Pencil': {'CATEGORY': 'Stationery', 'TYPE': 'Writing Tool', 'INFO': 'Uses graphite to create erasable marks.', 'MATERIAL': 'Wood/Graphite'},
    'Book': {'CATEGORY': 'Education', 'TYPE': 'Reading Material', 'INFO': 'A set of printed pages bound together.', 'PAGES': 'Variable'},
    'Notebook': {'CATEGORY': 'Education', 'TYPE': 'Writing Material', 'INFO': 'Blank pages used for taking notes.', 'PAGES': 'Variable'},
    'Eraser': {'CATEGORY': 'Stationery', 'TYPE': 'Correction Tool', 'INFO': 'Removes pencil marks from paper.', 'MATERIAL': 'Rubber'},
    'Ruler': {'CATEGORY': 'Stationery', 'TYPE': 'Measuring Tool', 'INFO': 'Used for measuring length or drawing straight lines.', 'MATERIAL': 'Plastic/Wood'},
    'Backpack': {'CATEGORY': 'Accessory', 'TYPE': 'Storage', 'INFO': 'A bag carried on the back, typically for school or hiking.', 'MATERIAL': 'Fabric'},
    'Desk': {'CATEGORY': 'Furniture', 'TYPE': 'Workspace', 'INFO': 'A table used for reading, writing, or computer work.', 'MATERIAL': 'Wood/Metal'},
    'Chair': {'CATEGORY': 'Furniture', 'TYPE': 'Seating', 'INFO': 'A seat typically designed for one person.', 'LEGS': '4'},
    'Whiteboard': {'CATEGORY': 'Education', 'TYPE': 'Presentation', 'INFO': 'A wipeable surface for writing with dry-erase markers.', 'SURFACE': 'Glossy'},
    'Marker': {'CATEGORY': 'Stationery', 'TYPE': 'Writing Tool', 'INFO': 'A pen with a broad tip for bold writing.', 'INK': 'Permanent/Dry-erase'},
    'Laptop': {'CATEGORY': 'Electronics', 'TYPE': 'Computer', 'INFO': 'A portable personal computer.', 'POWER': 'Battery'},
    'Computer': {'CATEGORY': 'Electronics', 'TYPE': 'Machine', 'INFO': 'An electronic device for processing data.', 'POWER': 'AC'},
    'Monitor': {'CATEGORY': 'Electronics', 'TYPE': 'Display', 'INFO': 'An output device that displays visual information.', 'RESOLUTION': 'HD/4K'},
    'Keyboard': {'CATEGORY': 'Electronics', 'TYPE': 'Input Device', 'INFO': 'A panel of keys used for typing.', 'KEYS': '104'},
    'Mouse': {'CATEGORY': 'Electronics', 'TYPE': 'Input Device', 'INFO': 'A hand-held pointing device.', 'SENSOR': 'Optical'},
    'Phone': {'CATEGORY': 'Electronics', 'TYPE': 'Communication', 'INFO': 'A portable cellular device for calls and apps.', 'CONNECTIVITY': 'Cellular/WiFi'},
    'Tablet': {'CATEGORY': 'Electronics', 'TYPE': 'Computer', 'INFO': 'A touchscreen portable device.', 'OS': 'Mobile'},
    'Clock': {'CATEGORY': 'Appliance', 'TYPE': 'Timepiece', 'INFO': 'A device used for measuring and indicating time.', 'DISPLAY': 'Analog/Digital'},
    'Bottle': {'CATEGORY': 'Container', 'TYPE': 'Drinkware', 'INFO': 'A vessel for holding liquids.', 'MATERIAL': 'Plastic/Glass/Metal'},
    'Lunchbox': {'CATEGORY': 'Container', 'TYPE': 'Food Storage', 'INFO': 'A box used for carrying food.', 'INSULATION': 'Optional'},
    'Apple': {'CATEGORY': 'Food', 'TYPE': 'Fruit', 'INFO': 'A round fruit with red or green skin.', 'NUTRITION': 'Vitamins/Fiber'},
    'Banana': {'CATEGORY': 'Food', 'TYPE': 'Fruit', 'INFO': 'A long curved fruit with a yellow skin.', 'NUTRITION': 'Potassium'},
    'Cup': {'CATEGORY': 'Container', 'TYPE': 'Drinkware', 'INFO': 'A small bowl-shaped container for drinking.', 'HANDLE': 'Yes'},
    'Mug': {'CATEGORY': 'Container', 'TYPE': 'Drinkware', 'INFO': 'A large cup, typically cylindrical, used for hot drinks.', 'MATERIAL': 'Ceramic'},
    'Glasses': {'CATEGORY': 'Accessory', 'TYPE': 'Eyewear', 'INFO': 'Lenses worn to correct or aid vision.', 'LENSES': 'Prescription'},
    'Sunglasses': {'CATEGORY': 'Accessory', 'TYPE': 'Eyewear', 'INFO': 'Glasses tinted to protect eyes from sunlight.', 'LENSES': 'UV Protection'},
    'Keys': {'CATEGORY': 'Tool', 'TYPE': 'Security', 'INFO': 'Metal instruments used for opening locks.', 'MATERIAL': 'Brass/Steel'},
    'Wallet': {'CATEGORY': 'Accessory', 'TYPE': 'Storage', 'INFO': 'A pocket-sized flat folding case for money and cards.', 'MATERIAL': 'Leather/Fabric'},
    'Shoes': {'CATEGORY': 'Clothing', 'TYPE': 'Footwear', 'INFO': 'Coverings for the feet.', 'PAIR': 'Yes'},
    'Sneakers': {'CATEGORY': 'Clothing', 'TYPE': 'Footwear', 'INFO': 'Athletic shoes with a flexible sole.', 'USAGE': 'Sports/Casual'},
    'Jacket': {'CATEGORY': 'Clothing', 'TYPE': 'Outerwear', 'INFO': 'A garment for the upper body, worn outdoors.', 'CLOSURE': 'Zipper/Buttons'},
    'Shirt': {'CATEGORY': 'Clothing', 'TYPE': 'Top', 'INFO': 'A garment for the upper body.', 'SLEEVES': 'Variable'},
    'Pants': {'CATEGORY': 'Clothing', 'TYPE': 'Bottom', 'INFO': 'A garment covering the body from the waist to the ankles.', 'LEGS': '2'},
    'Hat': {'CATEGORY': 'Clothing', 'TYPE': 'Headwear', 'INFO': 'A covering for the head.', 'BRIM': 'Optional'},
    'Door': {'CATEGORY': 'Architecture', 'TYPE': 'Entryway', 'INFO': 'A hinged or sliding barrier at the entrance to a room or building.', 'MATERIAL': 'Wood/Metal/Glass'},
    'Window': {'CATEGORY': 'Architecture', 'TYPE': 'Opening', 'INFO': 'An opening in a wall to admit light or air.', 'MATERIAL': 'Glass'},
    'Table': {'CATEGORY': 'Furniture', 'TYPE': 'Surface', 'INFO': 'A piece of furniture with a flat top and one or more legs.', 'USAGE': 'Dining/Working'},
    'Sofa': {'CATEGORY': 'Furniture', 'TYPE': 'Seating', 'INFO': 'A long upholstered seat with a back and arms.', 'CAPACITY': '2+ people'},
    'Bed': {'CATEGORY': 'Furniture', 'TYPE': 'Resting', 'INFO': 'A piece of furniture for sleep or rest.', 'MATTRESS': 'Yes'},
    'Pillow': {'CATEGORY': 'Bedding', 'TYPE': 'Support', 'INFO': 'A rectangular cloth bag stuffed with soft materials.', 'USAGE': 'Head support'},
    'Blanket': {'CATEGORY': 'Bedding', 'TYPE': 'Cover', 'INFO': 'A large piece of woolen or similar material used as a covering.', 'WARMTH': 'High'},
    'Lamp': {'CATEGORY': 'Appliance', 'TYPE': 'Lighting', 'INFO': 'A device for giving light.', 'POWER': 'Electricity'},
    'Television': {'CATEGORY': 'Electronics', 'TYPE': 'Display', 'INFO': 'A system for transmitting visual images and sound.', 'RESOLUTION': 'HD/4K/8K'},
    'Remote': {'CATEGORY': 'Electronics', 'TYPE': 'Controller', 'INFO': 'A device for operating machinery from a distance.', 'SIGNAL': 'Infrared/Bluetooth'},
    'Plant': {'CATEGORY': 'Nature', 'TYPE': 'Flora', 'INFO': 'A living organism of the kind exemplified by trees, shrubs, herbs, etc.', 'NEEDS': 'Water/Sunlight'},
    'Scissors': {'CATEGORY': 'Tool', 'TYPE': 'Cutting', 'INFO': 'An instrument used for cutting cloth, paper, and other thin material.', 'BLADES': '2'},
    'Glue': {'CATEGORY': 'Stationery', 'TYPE': 'Adhesive', 'INFO': 'A sticky substance used for joining things together.', 'STATE': 'Liquid/Solid'},
    'Calculator': {'CATEGORY': 'Electronics', 'TYPE': 'Computing', 'INFO': 'Something used for making mathematical calculations.', 'POWER': 'Battery/Solar'},
    'Stapler': {'CATEGORY': 'Stationery', 'TYPE': 'Fastener', 'INFO': 'A device for fastening together sheets of paper with a staple.', 'CAPACITY': 'Variable'},
    'Food': {'CATEGORY': 'Nutrition', 'TYPE': 'Consumable', 'INFO': 'Any nutritious substance that people or animals eat.', 'ENERGY': 'Calories'},
    'Fashion good': {'CATEGORY': 'Clothing/Accessory', 'TYPE': 'Apparel', 'INFO': 'Items worn on the body.', 'STYLE': 'Variable'},
    'Home good': {'CATEGORY': 'Household', 'TYPE': 'Item', 'INFO': 'Items used within the home.', 'USAGE': 'Domestic'},
    'Place': {'CATEGORY': 'Location', 'TYPE': 'Environment', 'INFO': 'A particular position or point in space.', 'SCALE': 'Variable'},
  };
}
