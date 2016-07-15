requires "App::Cmd::Setup" => "0";
requires "Config::Any" => "0";
requires "Cwd" => "0";
requires "Date::Parse" => "0";
requires "DateTime::Format::Strptime" => "0";
requires "DateTime::Set" => "0";
requires "File::HomeDir" => "0";
requires "File::Spec" => "0";
requires "JSON::MaybeXS" => "0";
requires "Search::Elasticsearch" => "0";
requires "Term::ProgressBar" => "0";
requires "autodie" => "0";
requires "lib" => "0";
requires "perl" => "5.010";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "Test::More" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};
