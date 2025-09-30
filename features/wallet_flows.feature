Feature: Aptos wallet devnet flows
  In order to exercise wallet journeys end to end
  BDD teams want reliable primitives for creating and funding Aptos accounts

  Background:
    Given an Aptos devnet client

  Scenario: Funding a freshly generated wallet
    When I create a fresh devnet wallet
    And I fund the wallet with 1000000 Octas
    Then the wallet balance should be at least 1000000 Octas

  Scenario: Funding twice accumulates balance
    When I create a fresh devnet wallet
    And I fund the wallet with 500000 Octas
    And I fund the wallet with 250000 Octas
    Then the wallet balance should be at least 750000 Octas
