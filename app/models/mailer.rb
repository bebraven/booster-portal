#
# Copyright (C) 2011 - 2015 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require 'mail'

class Mailer < ActionMailer::Base

  attr_reader :email

  # define in rails3-style
  def create_message(m)
    # notifications have context, bounce replies don't.
    headers('Auto-Submitted' => m.context ? 'auto-generated' : 'auto-replied')

    params = {
      from: from_mailbox(m),
      to: m.to,
      subject: m.subject
    }

    reply_to = reply_to_mailbox(m)
    params[:reply_to] = reply_to if reply_to

    mail(params) do |format|
      format.text{ render text: m.body }
      format.html{ render text: m.html_body } if m.html_body
    end
  end

  def debug_message(subj, txt, to_attach = nil)
    params = {
      from: quoted_address(HostUrl.outgoing_email_default_name, HostUrl.outgoing_email_address),
      to: 'tech@bebraven.org',
      subject: subj
    }

    if !to_attach.nil?
      to_attach.each do |key, value|
        attachments[key] = value
      end
    end

    mail(params) do |format|
      format.text{ render text: txt }
    end
  end

  def bz_message(to, subj, txt, to_attach = nil)
    params = {
      from: quoted_address(HostUrl.outgoing_email_default_name, HostUrl.outgoing_email_address),
      to: to,
      subject: subj
    }

    if !to_attach.nil?
      to_attach.each do |key, value|
        attachments[key] = {
          mime_type: "text/csv",
          encoding: "base64",
          content: Base64.encode64(value)
        }
      end
    end

    mail(params) do |format|
      format.text{ render text: txt }
    end
  end


  private
  def quoted_address(display_name, address)
    addr = Mail::Address.new(address)
    addr.display_name = display_name
    addr.format
  end

  def from_mailbox(message)
    quoted_address(message.from_name || HostUrl.outgoing_email_default_name, HostUrl.outgoing_email_address)
  end

  def reply_to_mailbox(message)
    address = IncomingMail::ReplyToAddress.new(message).address
    return address unless message.reply_to_name.present?
    return nil unless address.present?

    quoted_address(message.reply_to_name, address)
  end
end
