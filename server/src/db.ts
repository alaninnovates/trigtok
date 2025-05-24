import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { Transcript } from './transcript';

export class Database {
    private client: SupabaseClient;

    constructor(supabaseUrl: string, supabaseKey: string) {
        this.client = createClient(supabaseUrl, supabaseKey);
    }

    public async explanationExists(
        unitId: number,
        topic: string,
    ): Promise<{
        exists: boolean;
        error: boolean;
        data: any;
    }> {
        const { data, error } = await this.client
            .from('explanations')
            .select('id')
            .eq('unit', unitId)
            .eq('topic', topic)
            .limit(1);

        if (error) {
            return {
                exists: false,
                error: true,
                data: error.message,
            };
        }

        return {
            exists: data.length > 0,
            error: false,
            data,
        };
    }

    public async getUnitInfo(unitId: number): Promise<{
        className: string;
        unitName: string;
        topics: string[];
    } | null> {
        const { data, error } = await this.client
            .from('units')
            .select('name, topics, classes(name)')
            .eq('id', unitId)
            .single();

        if (error) {
            console.error('Error fetching unit:', error);
            return null;
        }

        return data
            ? {
                  // @ts-ignore
                  className: data.classes.name,
                  unitName: data.name,
                  topics: data.topics,
              }
            : null;
    }

    public async storeExplanation(
        unitId: number,
        topic: string,
        transcript: Transcript,
        audioUrl: string,
    ): Promise<{
        success: boolean;
        data: any;
    }> {
        const { data, error } = await this.client
            .from('explanations')
            .insert({
                unit: unitId,
                topic: topic,
                transcript: transcript,
                audio_url: audioUrl,
            })
            .select();

        if (error) {
            return {
                success: false,
                data: error.message,
            };
        }

        return {
            success: true,
            data,
        };
    }
}
