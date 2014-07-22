#
# Copyright (c) 2014 Red Hat Inc.
#
# This software is licensed to you under the GNU General Public License,
# version 2 (GPLv2). There is NO WARRANTY for this software, express or
# implied, including the implied warranties of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. You should have received a copy of GPLv2
# along with this software; if not, see
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt.
#

require 'smart-proxy_openscap/openscap_lib'

module Proxy::OpenSCAP
  class Api < ::Sinatra::Base
    include ::Proxy::Log
    helpers ::Proxy::Helpers

    put "/arf/:policy/:date" do
      # first let's verify client's certificate
      begin
        cn = Proxy::OpenSCAP::common_name request
      rescue Proxy::Error::Unauthorized => e
        log_halt 403, "Client authentication failed: #{e.message}"
      end

      # validate the url (i.e. avoid malformed :policy)
      begin
        target_path = Proxy::OpenSCAP::spool_arf_path(cn, params[:policy], params[:date])
      rescue Proxy::Error::BadRequest => e
        log_halt 400, "Requested URI is malformed: #{e.message}"
      rescue StandardError => e
        log_halt 500, "Could not fulfill request: #{e.message}"
      end

      begin
        File.open(target_path,'w') { |f| f.write(request.body.string) }
      rescue StandardError => e
        log_halt 500, "Could not store file: #{e.message}"
      end

      logger.debug "File #{target_path} stored successfully."

      {"created" => true}.to_json
    end
  end
end
