import { useState } from 'react';
import { db } from '../firebase';
import { collection, getDocs, writeBatch, doc } from 'firebase/firestore';

const shopsData = [
    {
        name: "Flame & Grill",
        description: "Charcoal grilled burgers & peri-peri chicken.",
        category: "Fast Food",
        openingHours: "09:00 AM - 09:00 PM",
        icon: "flame",
        menu: [
            { name: "Wagyu Beef Burger", price: 1250, description: "Premium wagyu patty with caramelized onions." },
            { name: "Peri-Peri Wings (6pcs)", price: 850, description: "Spicy grilled wings with signature dip." },
            { name: "Truffle Parmesan Fries", price: 450, description: "Crispy fries tossed in truffle oil." },
            { name: "Classic Cheeseburger", price: 950, description: "Juicy beef patty with aged cheddar." },
            { name: "Grilled Chicken Wrap", price: 750, description: "Roasted chicken with fresh greens." }
        ]
    },
    {
        name: "Pizza Paradiso",
        description: "Authentic stone-baked Italian pizzas.",
        category: "Fast Food",
        openingHours: "10:00 AM - 10:00 PM",
        icon: "pizza",
        menu: [
            { name: "Margherita Classic", price: 1400, description: "Fresh mozzarella, basil and olive oil." },
            { name: "Pepperoni Feast", price: 1850, description: "Double pepperoni with herb crust." },
            { name: "Truffle Mushroom", price: 1950, description: "White sauce base with wild mushrooms." },
            { name: "Spicy Hawaiian", price: 1600, description: "Pineapple, jalapeños and turkey ham." },
            { name: "Garden Veggie", price: 1350, description: "Mixed bell peppers, olives and corn." }
        ]
    },
    {
        name: "Brew & Bloom",
        description: "Specialty Arabica and artisanal pastries.",
        category: "Coffee",
        openingHours: "07:30 AM - 07:00 PM",
        icon: "coffee",
        menu: [
            { name: "Iced Spanish Latte", price: 650, description: "Sweetened condensed milk and double espresso." },
            { name: "Flat White", price: 550, description: "Micro-foam milk over smooth espresso." },
            { name: "Almond Croissant", price: 400, description: "Double baked with almond frangipane." },
            { name: "Matcha Latte", price: 600, description: "Ceremonial grade matcha with oat milk." },
            { name: "Blueberry Muffin", price: 350, description: "Soft muffin bursting with fresh fruit." }
        ]
    },
    {
        name: "The Coffee Hub",
        description: "Your daily dose of caffeine and quick bites.",
        category: "Coffee",
        openingHours: "08:00 AM - 08:00 PM",
        icon: "cup-soda",
        menu: [
            { name: "Signature Cappuccino", price: 500, description: "Cocoa dusted classic creamy coffee." },
            { name: "Dark Roast Americano", price: 400, description: "Bold and intense long black coffee." },
            { name: "Caramel Macchiato", price: 650, description: "Vanilla syrup, steamed milk and caramel drizzle." },
            { name: "Chicken & Mayo Sandwich", price: 550, description: "Crispy bread with creamy chicken filling." },
            { name: "Chocolate Cookie", price: 200, description: "Giant chunky dark chocolate cookie." }
        ]
    },
    {
        name: "Green Bowl",
        description: "Nutrient-rich salads and healthy quinoa bowls.",
        category: "Healthy",
        openingHours: "09:00 AM - 06:00 PM",
        icon: "leaf",
        menu: [
            { name: "Mediterranean Bowl", price: 950, description: "Quinoa, hummus, olives and feta." },
            { name: "Avocado Toast Deluxe", price: 800, description: "Sourdough with poached egg and seeds." },
            { name: "Pesto Pasta Salad", price: 750, description: "Fusilli with homemade basil pesto." },
            { name: "Falafel Wrap", price: 650, description: "Spiced chickpeas with tahini dressing." },
            { name: "Detox Green Bowl", price: 850, description: "Kale, spinach, nuts and berry vinaigrette." }
        ]
    },
    {
        name: "Vitality Squeeze",
        description: "Freshly pressed seasonal juices and fruit bowls.",
        category: "Healthy",
        openingHours: "08:00 AM - 07:00 PM",
        icon: "glass-water",
        menu: [
            { name: "Orange Immunity", price: 450, description: "100% fresh squeezed orange juice." },
            { name: "Pink Dragon Smoothie", price: 600, description: "Pitaya, banana and coconut water." },
            { name: "Tropical Fruit Platter", price: 550, description: "Mixed seasonal island fruits." },
            { name: "Ginger Lemon Shot", price: 250, description: "Concentrated ginger juice booster." },
            { name: "Berry Blast", price: 580, description: "Mixed berries blended with honey." }
        ]
    },
    {
        name: "Crunch Corner",
        description: "Classic campus bites, rolls and short eats.",
        category: "Snacks",
        openingHours: "08:00 AM - 08:00 PM",
        icon: "apple",
        menu: [
            { name: "Crispy Chicken Roll", price: 150, description: "Fried roll with spiced chicken potato." },
            { name: "Vegetable Samosa (2pcs)", price: 100, description: "Classic crunchy crust with peas & spice." },
            { name: "Potato Wedges", price: 400, description: "Oven baked with skins on." },
            { name: "Hot Butter Cuttlefish", price: 950, description: "Crispy fried cuttlefish with chili." },
            { name: "Mini Prawn Buns", price: 120, description: "Soft bread with spicy prawn filling." }
        ]
    },
    {
        name: "Taco Central",
        description: "Fusion tacos and loaded cheesy nachos.",
        category: "Snacks",
        openingHours: "10:00 AM - 09:00 PM",
        icon: "cookie",
        menu: [
            { name: "Spicy Beef Tacos", price: 900, description: "Soft tortillas with slow cooked beef." },
            { name: "Ultimate Nachos", price: 1100, description: "Cheese sauce, salsa and jalapeños." },
            { name: "Chicken Quesadilla", price: 850, description: "Toasted flour tortilla with cheese." },
            { name: "Corn on the Cob", price: 300, description: "Grilled with chili lime butter." },
            { name: "Churros with Chocolate", price: 550, description: "Fried dough with cinnamon sugar." }
        ]
    },
    {
        name: "Velvet Bites",
        description: "Decadent cupcakes, brownies and milkshakes.",
        category: "Dessert",
        openingHours: "10:00 AM - 08:00 PM",
        icon: "cake",
        menu: [
            { name: "Red Velvet Cupcake", price: 300, description: "Moist cake with cream cheese frosting." },
            { name: "Gooey Fudge Brownie", price: 350, description: "Dense chocolate brownie with nuts." },
            { name: "Strawberry Milkshake", price: 650, description: "Real strawberries blended with cream." },
            { name: "New York Cheesecake", price: 850, description: "Rich and creamy with berry coulis." },
            { name: "Rainbow Macarons", price: 450, description: "Three assorted french macarons." }
        ]
    },
    {
        name: "Ice Cream Isle",
        description: "Premium gelato and dessert sundaes.",
        category: "Dessert",
        openingHours: "11:00 AM - 10:00 PM",
        icon: "ice-cream",
        menu: [
            { name: "Double Chocolate Gelato", price: 400, description: "Two scoops of rich artisanal gelato." },
            { name: "Classic Banana Split", price: 750, description: "Three flavors with fudge and nuts." },
            { name: "Vanilla Bean Cone", price: 250, description: "Madagascar vanilla in waffle cone." },
            { name: "Mango Sorbet Bowl", price: 450, description: "Dairy-free fresh mango sorbet." },
            { name: "Oreo Sundae", price: 600, description: "Crushed cookies with cream and sauce." }
        ]
    }
];

export default function SeedingTool() {
    const [status, setStatus] = useState('Idle');

    const handleSeed = async () => {
        setStatus('Clearing old data...');
        try {
            // 1. Clear old shops
            const shopsCol = collection(db, 'cafeteria_shops');
            const shopsSnap = await getDocs(shopsCol);
            let batch = writeBatch(db);
            shopsSnap.docs.forEach(d => batch.delete(d.ref));
            await batch.commit();

            // 2. Clear old menu
            const menuCol = collection(db, 'cafeteria_menu');
            const menuSnap = await getDocs(menuCol);
            batch = writeBatch(db);
            menuSnap.docs.forEach(d => batch.delete(d.ref));
            await batch.commit();

            // 3. Add new data
            setStatus('Adding new shops...');
            for (const shop of shopsData) {
                const newShopRef = doc(shopsCol);
                const { menu, ...shopData } = shop;
                
                batch = writeBatch(db);
                batch.set(newShopRef, {
                    ...shopData,
                    isActive: true,
                    createdAt: new Date()
                });

                menu.forEach(item => {
                    const newItemRef = doc(menuCol);
                    batch.set(newItemRef, {
                        ...item,
                        shopId: newShopRef.id,
                        currency: 'LKR',
                        category: 'General',
                        quantity: 100,
                        preparationMinutes: 15,
                        status: 'Available',
                        createdAt: new Date()
                    });
                });
                await batch.commit();
                console.log(`Added shop: ${shop.name}`);
            }

            setStatus('Seeding Successful! You can close this page.');
        } catch (err) {
            console.error(err);
            setStatus(`Failed: ${err.message}`);
        }
    };

    return (
        <div style={{ padding: '40px', fontFamily: 'sans-serif', textAlign: 'center' }}>
            <h1>UniLink Cafeteria Seeder</h1>
            <p>This tool will populate Firestore with 10 premium shops and 50+ menu items.</p>
            <div style={{ margin: '20px 0', padding: '20px', background: '#f5f5f5', borderRadius: '8px' }}>
                <strong>Status:</strong> {status}
            </div>
            <button 
                onClick={handleSeed}
                disabled={status.includes('Seeding') || status.includes('Clearing')}
                style={{
                    padding: '12px 24px',
                    fontSize: '16px',
                    backgroundColor: '#6366F1',
                    color: 'white',
                    border: 'none',
                    borderRadius: '8px',
                    cursor: 'pointer'
                }}
            >
                Run Seeding
            </button>
        </div>
    );
}
