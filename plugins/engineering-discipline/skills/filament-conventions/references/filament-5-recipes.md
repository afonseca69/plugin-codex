# Filament v5 Recipes

This reference adapts the upstream Filament v5 recipe material. It was sourced
from examples verified against Filament v5.6.7 vendor files. Before applying it
in a target project, confirm the installed Filament major/minor version from
`composer.lock`, `composer.json`, vendor source, or official docs in that
project.

## Namespaces And Component Locations

| Concern | v5 namespace / class |
|---|---|
| Schema container | `Filament\Schemas\Schema` |
| Layout section | `Filament\Schemas\Components\Section` |
| Fieldset | `Filament\Schemas\Components\Fieldset` |
| Form fields | `Filament\Forms\Components\*` |
| Actions | `Filament\Actions\*` |
| Relation manager | `Filament\Resources\RelationManagers\RelationManager` |
| Table | `Filament\Tables\Table` |

In Filament v5, a resource form uses `Schema`, not the older `Form` signature:

```php
use Filament\Schemas\Schema;

public static function form(Schema $schema): Schema
{
    return ContactForm::configure($schema);
}
```

The top-level schema uses `->components([...])`. Layout components such as
`Section` and `Fieldset` use `->schema([...])`.

## Form Organization

Start with grouped layout, then fields.

```php
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Components\Fieldset;
use Filament\Schemas\Components\Section;

return $schema->components([
    Section::make('Company')
        ->description('Where this contact works')
        ->columns(2)
        ->schema([
            Select::make('company_id')
                ->relationship('company', 'name')
                ->searchable()
                ->preload(),
        ]),

    Fieldset::make('Identity')
        ->schema([
            TextInput::make('first_name')->required(),
            TextInput::make('last_name'),
        ]),
]);
```

## Navigation Groups

Filament v5 resources and pages support `string | UnitEnum | null` navigation
groups. Prefer an existing enum/constant when the project has one.

```php
use UnitEnum;

protected static string | UnitEnum | null $navigationGroup = 'CRM';
```

## Relation Managers

Generate relation managers through Artisan when available:

```bash
php artisan make:filament-relation-manager ContactResource tags name
```

Register them on the resource:

```php
public static function getRelations(): array
{
    return [
        TagsRelationManager::class,
        ActivitiesRelationManager::class,
    ];
}
```

Each relation manager owns its own form/table behavior:

```php
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Schemas\Schema;
use Filament\Tables\Table;

class TagsRelationManager extends RelationManager
{
    protected static string $relationship = 'tags';

    public function form(Schema $schema): Schema
    {
        return $schema->components([
            // ...
        ]);
    }

    public function table(Table $table): Table
    {
        return $table->columns([
            // ...
        ]);
    }
}
```

## Delete Actions Belong In The Table Flow

The generator may place a `DeleteAction` on the edit page header. If the product
convention is "delete from list", remove that edit-page header action and put
delete in table row/bulk actions.

```php
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteAction;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;

return $table
    ->recordActions([
        EditAction::make(),
        DeleteAction::make(),
    ])
    ->toolbarActions([
        BulkActionGroup::make([
            DeleteBulkAction::make(),
        ]),
    ]);
```

Prefer v5 `recordActions()` and `toolbarActions()` method names over older
aliases when the installed version supports them.

## Redirect Create And Edit Saves To The Index

Panel-wide configuration is the simplest consistent approach:

```php
$panel
    ->resourceCreatePageRedirect('index')
    ->resourceEditPageRedirect('index');
```

Per-page override when the project convention prefers local behavior:

```php
protected function getRedirectUrl(): string
{
    return $this->getResource()::getUrl('index');
}
```

## Profile / Settings In User Menu

Register a profile page so account management lives in the user menu:

```php
$panel->profile();

// or
$panel->profile(\App\Filament\Pages\Settings::class);
```

Add custom user-menu items only when the product needs them:

```php
use Filament\Actions\Action;

$panel->userMenuItems([
    Action::make('billing')
        ->label('Billing')
        ->url(fn () => route('billing')),
]);
```

## Native Auth And Optional App MFA

When the installed Filament version supports native MFA, prefer the framework
provider over custom MFA screens.

```php
use Filament\Auth\MultiFactor\App\AppAuthentication;

$panel
    ->login()
    ->profile()
    ->multiFactorAuthentication([
        AppAuthentication::make()->recoverable(),
    ]);
```

The user model must implement the contracts required by the installed Filament
version for storing app-auth secrets and recovery codes. Store those fields with
appropriate encryption/casts according to the target project conventions.

## No Public Registration

For closed admin panels, do not call `->registration()`.

Provision users through the project-approved path, such as:

```bash
php artisan make:filament-user
```

or a custom invite flow.

## Combined Panel Example

```php
use Filament\Auth\MultiFactor\App\AppAuthentication;
use Filament\Panel;

public function panel(Panel $panel): Panel
{
    return $panel
        ->default()
        ->id('admin')
        ->path('admin')
        ->login()
        ->profile()
        ->multiFactorAuthentication([
            AppAuthentication::make()->recoverable(),
        ])
        ->resourceCreatePageRedirect('index')
        ->resourceEditPageRedirect('index')
        ->discoverResources(
            in: app_path('Filament/Resources'),
            for: 'App\\Filament\\Resources',
        )
        ->discoverPages(
            in: app_path('Filament/Pages'),
            for: 'App\\Filament\\Pages',
        );
}
```

## Verification Checklist

- Installed Filament version supports the APIs used.
- Resource form uses grouped layout.
- Relation managers cover important Eloquent relations.
- Edit page does not expose delete when the product expects table/list deletes.
- Create/edit redirects match the product convention.
- Panel has intended login/profile/MFA/registration behavior.
- Relevant tests or manual Filament smoke checks ran and are reported.
