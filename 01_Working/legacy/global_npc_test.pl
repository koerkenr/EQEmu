# global_npc.pl - Test to see what loot NPCs have at spawn

use strict;
use warnings;

our (
  $npc,
  $client,
  $zoneid,
  $text,
  $status,
  $entity_list
);

sub EVENT_SPAWN {
  return unless $npc;
  
  # Get loot count
  my $loot_count = $npc->CountLoot();
  
  quest::shout("I have $loot_count items in my loot!");
  quest::debug("NPC " . $npc->GetCleanName() . " has $loot_count items at spawn");
  
  # Try to get loot list
  my @loot_list = $npc->GetLootList();
  
  if (@loot_list) {
    quest::shout("My loot list has " . scalar(@loot_list) . " entries!");
    quest::debug("Loot list: " . join(", ", @loot_list));
    
    foreach my $item_id (@loot_list) {
      quest::debug("  - Item ID: $item_id");
    }
  } else {
    quest::shout("My loot list is empty!");
  }
}

1;
