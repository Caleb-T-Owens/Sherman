# BotHub

Plugin manifest:

```json
{
    "commands": {
        "dadjoke": {
            "description": "Tells a dad joke"
        },
        "toggle-lights": {
            "description": "Toggles the lights in a particular room",
            "args": [
                {
                    "name": "room",
                    "type": "string",
                    "optional": false
                }
            ]
        }
    },
    // Roles that get referenced by the plugin (we would have some logic behind the scenes to link them to actual roles)
    "roles": {
        "admin": {}
    }
}
```

Example

```ts
bot.handleCommand("dadjoke", async (context) => {
    await context.reply(
        "Why did the chicken cross the road? To get to the other side!"
    );
});

bot.handleCommand("toggle-lights", async (context) => {
    if (context.author.hasRole("admin")) {
        await externalLightsApi.toggleLight(context.args.room);
        await context.reply("Lights have been toggled");
    } else {
        await context.reply("Access denied");
    }
});
```
