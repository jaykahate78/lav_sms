<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class DatabaseSeeder extends Seeder
{
    /**
     * Populate a dedicated synthetic demo database. Skip already populated
     * reference tables on Render restarts; never delete existing user accounts.
     */
    public function run()
    {
        $seeders = [
            ['blood_groups', BloodGroupsTableSeeder::class],
            ['grades', GradesTableSeeder::class],
            ['dorms', DormsTableSeeder::class],
            ['class_types', ClassTypesTableSeeder::class],
            ['user_types', UserTypesTableSeeder::class],
            ['my_classes', MyClassesTableSeeder::class],
            ['nationalities', NationalitiesTableSeeder::class],
            ['states', StatesTableSeeder::class],
            ['lgas', LgasTableSeeder::class],
            ['settings', SettingsTableSeeder::class],
            ['users', UsersTableSeeder::class],
            ['subjects', SubjectsTableSeeder::class],
            ['sections', SectionsTableSeeder::class],
            ['student_records', StudentRecordsTableSeeder::class],
            ['skills', SkillsTableSeeder::class],
        ];

        foreach ($seeders as [$table, $seeder]) {
            if (DB::table($table)->exists()) {
                $this->command->info("Skipping already populated demo table: {$table}");
                continue;
            }
            $this->call($seeder);
        }
    }
}
