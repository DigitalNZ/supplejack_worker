# frozen_string_literal: true
# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
HarvesterWorker::Application.config.secret_key_base = ENV['SECRET_KEY_BASE'] || '861d1fe797f8e07f8e0dd3a7f8e0d7f8e0d3a97f8e0d3a7f7f88e0d3a7fe0d7f'
